use crate::{
    core::constants::errors::AppError,
    features::{
        auth::{
            helpers::{password::password_is_valid, token::generate_tokens},
            structs::{requests::RecoverAccountUsingPasswordRequest, responses::UserLoginResponse},
        },
        profile::structs::models::User,
    },
};
use actix_web::{post, web, HttpResponse, Responder};
use argon2::{Argon2, PasswordHash, PasswordVerifier};
use sqlx::PgPool;

#[post("/recover-using-password")]
pub async fn recover_account_using_password(
    body: web::Json<RecoverAccountUsingPasswordRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response())
        }
    };

    let body = body.into_inner();
    let username_lower = body.username.to_lowercase();

    // Check if user already exists
    let existing_user = sqlx::query_as!(
        User,
        r#"
        SELECT *
        FROM users
        WHERE username = $1
        "#,
        username_lower,
    )
    .fetch_optional(&mut *transaction)
    .await;

    let mut user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::Unauthorized()
                    .json(AppError::InvalidUsernameOrPasswordOrRecoveryCode.to_response());
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(AppError::DatabaseQuery.to_response())
        }
    };

    // 2FA should be enabled to pass here
    if !user.otp_verified {
        return HttpResponse::Forbidden()
            .json(AppError::TwoFactorAuthenticationNotEnabled.to_response());
    }

    // Check password
    if !password_is_valid(&user, &body.password) {
        return HttpResponse::Unauthorized()
            .json(AppError::InvalidUsernameOrPasswordOrRecoveryCode.to_response());
    }

    // Check recovery code
    let mut is_valid = false;

    for recovery_code in user.recovery_codes.split(";") {
        let parsed_hash = if let Ok(parsed_hash) = PasswordHash::new(recovery_code) {
            parsed_hash
        } else {
            return HttpResponse::InternalServerError().json(AppError::PasswordHash.to_response());
        };

        let argon2 = Argon2::default();

        is_valid = argon2
            .verify_password(body.recovery_code.as_bytes(), &parsed_hash)
            .is_ok();

        if is_valid {
            // Remove recovery code in db
            let mut new_recovery_codes = Vec::<String>::new();

            for rcode in user.recovery_codes.split(";") {
                if rcode != recovery_code {
                    new_recovery_codes.push(rcode.to_string());
                }
            }

            let updated_user_result = sqlx::query!(
                r#"
                UPDATE users
                SET recovery_codes = $1
                WHERE id = $2
                "#,
                new_recovery_codes.join(";"),
                user.id
            )
            .fetch_optional(&mut *transaction)
            .await;

            if updated_user_result.is_err() {
                return HttpResponse::InternalServerError()
                    .json(AppError::UserUpdate.to_response());
            }

            break;
        }
    }

    if !is_valid {
        return HttpResponse::Unauthorized()
            .json(AppError::InvalidUsernameOrPasswordOrRecoveryCode.to_response());
    }

    // Delete any other existing tokens for that user
    let delete_result = sqlx::query!(
        r#"
            DELETE FROM user_tokens WHERE user_id = $1
            "#,
        user.id,
    )
    .execute(&mut *transaction)
    .await;

    if delete_result.is_err() {
        return HttpResponse::InternalServerError().json(AppError::UserTokenDeletion.to_response());
    }

    let (access_token, refresh_token) =
        match generate_tokens(secret.as_bytes(), user.id, &mut transaction).await {
            Ok((access_token, refresh_token)) => (access_token, refresh_token),
            Err(_) => {
                return HttpResponse::InternalServerError()
                    .json(AppError::TokenGeneration.to_response());
            }
        };

    user.otp_verified = false;
    user.otp_auth_url = None;
    user.otp_base32 = None;

    let updated_user_result = sqlx::query_scalar!(
        r#"
                UPDATE users
                SET otp_verified = $1, otp_auth_url = $2, otp_base32 = $3
                WHERE id = $4
                "#,
        user.otp_verified,
        user.otp_auth_url,
        user.otp_base32,
        user.id
    )
    .fetch_optional(&mut *transaction)
    .await;

    if updated_user_result.is_err() {
        return HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response());
    }

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    HttpResponse::Ok().json(UserLoginResponse {
        code: "USER_LOGGED_IN_AFTER_ACCOUNT_RECOVERY".to_string(),
        access_token,
        refresh_token,
    })
}
