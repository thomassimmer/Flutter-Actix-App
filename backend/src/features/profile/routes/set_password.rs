use actix_web::{post, web, HttpRequest, HttpResponse, Responder};
use argon2::{password_hash::SaltString, Argon2, PasswordHasher};
use chrono::{DateTime, Utc};
use rand::rngs::OsRng;
use sqlx::PgPool;

use crate::{
    core::{helpers::mock_now::now, structs::responses::GenericResponse},
    features::{
        auth::helpers::token::retrieve_claims_for_token,
        profile::structs::{
            models::User, requests::SetUserPasswordRequest, responses::UserResponse,
        },
    },
};

#[post("/set-password")]
pub async fn set_password(
    req: HttpRequest,
    body: web::Json<SetUserPasswordRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    match retrieve_claims_for_token(req, secret.to_string()) {
        Ok(claims) => {
            if now() > DateTime::<Utc>::from_timestamp(claims.exp as i64, 0).unwrap() {
                return HttpResponse::Unauthorized().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Token expired".to_string(),
                });
            }

            let jti = claims.jti;

            let mut transaction = match pool.begin().await {
                Ok(t) => t,
                Err(_) => {
                    return HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "Failed to get a transaction".to_string(),
                    })
                }
            };

            // Check if user already exists
            let existing_user = sqlx::query_as!(
                User,
                r#"
                SELECT u.*
                FROM users u
                JOIN user_tokens ut ON u.id = ut.user_id
                WHERE ut.token_id = $1
                "#,
                jti,
            )
            .fetch_optional(&mut *transaction)
            .await;

            let mut user = match existing_user {
                Ok(existing_user) => match existing_user {
                    Some(existing_user) => existing_user,
                    None => {
                        return HttpResponse::InternalServerError().json(GenericResponse {
                            status: "error".to_string(),
                            message: "No user found for this token".to_string(),
                        })
                    }
                },
                Err(_) => {
                    return HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "Database query error".to_string(),
                    })
                }
            };

            if !user.password_is_expired {
                return HttpResponse::BadRequest().json(GenericResponse {
                    status: "fail".to_string(),
                    message: "Password is not expired. You cannot set it here.".to_string(),
                });
            }

            // Hash the new password
            let salt = SaltString::generate(&mut OsRng);
            let argon2 = Argon2::default();
            let password_hash = match argon2.hash_password(body.new_password.as_bytes(), &salt) {
                Ok(hash) => hash.to_string(),
                Err(_) => {
                    return HttpResponse::BadRequest().json(GenericResponse {
                        status: "fail".to_string(),
                        message: "Failed to hash password".to_string(),
                    })
                }
            };

            user.password = password_hash;
            user.password_is_expired = false;

            let updated_user_result = sqlx::query!(
                r#"
                UPDATE users
                SET password = $1, password_is_expired = $2
                WHERE id = $3
                "#,
                user.password,
                user.password_is_expired,
                user.id
            )
            .fetch_optional(&mut *transaction)
            .await;

            if (transaction.commit().await).is_err() {
                return HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to commit transaction".to_string(),
                });
            }

            match updated_user_result {
                Ok(_) => HttpResponse::Ok().json(UserResponse {
                    status: "success".to_string(),
                    user: user.to_user_data(),
                }),
                Err(_) => HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to update user".to_string(),
                }),
            }
        }

        Err(_) => HttpResponse::Unauthorized().json(GenericResponse {
            status: "fail".to_string(),
            message: "Invalid access token".to_string(),
        }),
    }
}
