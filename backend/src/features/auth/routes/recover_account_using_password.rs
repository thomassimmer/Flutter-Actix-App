use crate::{
    core::structs::responses::GenericResponse,
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
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Failed to get a transaction".to_string(),
            })
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
                return HttpResponse::Forbidden().json(GenericResponse {
                    status: "fail".to_string(),
                    message: "Invalid username or password or recovery code".to_string(),
                });
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Database query error".to_string(),
            })
        }
    };

    // 2FA should be enabled to pass here
    if !user.otp_verified {
        let json_error = GenericResponse {
            status: "fail".to_string(),
            message: "2FA not enabled".to_string(),
        };

        return HttpResponse::Forbidden().json(json_error);
    }

    // Check password
    if !password_is_valid(&user, &body.password) {
        return HttpResponse::Forbidden().json(GenericResponse {
            status: "fail".to_string(),
            message: "Invalid username or password or recovery code".to_string(),
        });
    }

    // Check recovery code
    let mut is_valid = false;

    for recovery_code in user.recovery_codes.split(";") {
        let parsed_hash = if let Ok(parsed_hash) = PasswordHash::new(recovery_code) {
            parsed_hash
        } else {
            return HttpResponse::BadRequest().json(GenericResponse {
                status: "fail".to_string(),
                message: "Failed to retrieve hashed password".to_string(),
            });
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
                return HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to update user".to_string(),
                });
            }

            break;
        }
    }

    if !is_valid {
        return HttpResponse::Forbidden().json(GenericResponse {
            status: "fail".to_string(),
            message: "Invalid username or password or recovery code".to_string(),
        });
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
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to delete user tokens into the database".to_string(),
        });
    }

    let (access_token, refresh_token) =
        match generate_tokens(secret.as_bytes(), user.id, &mut transaction).await {
            Ok((access_token, refresh_token)) => (access_token, refresh_token),
            Err(_) => {
                return HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to generate and save token".to_string(),
                });
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
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to update user into the database".to_string(),
        });
    }

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to commit transaction".to_string(),
        });
    }

    HttpResponse::Ok().json(UserLoginResponse {
        status: "success".to_string(),
        access_token,
        refresh_token,
    })
}
