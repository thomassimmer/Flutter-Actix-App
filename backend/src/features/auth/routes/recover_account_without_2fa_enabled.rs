use crate::{
    core::structs::responses::GenericResponse,
    features::{
        auth::{
            helpers::token::generate_tokens,
            structs::{
                requests::RecoverAccountWithout2FAEnabledRequest, responses::UserLoginResponse,
            },
        },
        profile::structs::models::User,
    },
};
use actix_web::{post, web, HttpResponse, Responder};
use argon2::{Argon2, PasswordHash, PasswordVerifier};
use sqlx::PgPool;

#[post("/recover")]
pub async fn recover_account_without_2fa_enabled(
    body: web::Json<RecoverAccountWithout2FAEnabledRequest>,
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
                    message: "Invalid username or recovery code".to_string(),
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
            message: "Invalid username or recovery code".to_string(),
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

    user.password_is_expired = true;

    let updated_user_result = sqlx::query_scalar!(
        r#"
        UPDATE users
        SET password_is_expired = $1
        WHERE id = $2
        "#,
        user.password_is_expired,
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
