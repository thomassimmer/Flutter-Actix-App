use crate::{
    core::constants::errors::AppError,
    features::{
        auth::{
            helpers::{
                password::password_is_valid,
                token::{delete_user_tokens, generate_tokens},
            },
            structs::{requests::RecoverAccountUsingPasswordRequest, responses::UserLoginResponse},
        },
        profile::helpers::{
            device_info::get_user_agent,
            profile::{get_user_by_username, update_user},
        },
    },
};
use actix_web::{post, web, HttpRequest, HttpResponse, Responder};
use argon2::{Argon2, PasswordHash, PasswordVerifier};
use sqlx::PgPool;
use tracing::error;

#[post("/recover-using-password")]
pub async fn recover_account_using_password(
    req: HttpRequest,
    body: web::Json<RecoverAccountUsingPasswordRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response());
        }
    };

    let body = body.into_inner();
    let username_lower = body.username.to_lowercase();


    let existing_user = get_user_by_username(&mut *transaction, &username_lower).await;

    let mut user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::Unauthorized()
                    .json(AppError::InvalidUsernameOrPasswordOrRecoveryCode.to_response());
            }
        }
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError().json(AppError::DatabaseQuery.to_response());
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

            user.recovery_codes = new_recovery_codes.join(";");

            let updated_user_result = update_user(&mut *transaction, &user).await;

            if let Err(e) = updated_user_result {
                error!("Error: {}", e);
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
    let delete_result = delete_user_tokens(&mut *transaction, user.id).await;

    if let Err(e) = delete_result {
        error!("Error: {}", e);
        return HttpResponse::InternalServerError().json(AppError::UserTokenDeletion.to_response());
    }

    let parsed_device_info = get_user_agent(req).await;

    let (access_token, refresh_token) = match generate_tokens(
        &mut *transaction,
        secret.as_bytes(),
        user.id,
        user.is_admin,
        parsed_device_info,
    )
    .await
    {
        Ok((access_token, refresh_token)) => (access_token, refresh_token),
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError()
                .json(AppError::TokenGeneration.to_response());
        }
    };

    user.otp_verified = false;
    user.otp_auth_url = None;
    user.otp_base32 = None;

    let updated_user_result = update_user(&mut *transaction, &user).await;

    if let Err(e) = updated_user_result {
        error!("Error: {}", e);
        return HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response());
    }

    if let Err(e) = transaction.commit().await {
        error!("Error: {}", e);
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    HttpResponse::Ok().json(UserLoginResponse {
        code: "USER_LOGGED_IN_AFTER_ACCOUNT_RECOVERY".to_string(),
        access_token,
        refresh_token,
    })
}
