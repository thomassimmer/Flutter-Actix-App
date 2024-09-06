use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::token::retrieve_claims_for_token;
use crate::features::auth::structs::responses::DisableOtpResponse;
use crate::features::profile::structs::models::User;

use actix_web::{get, web, HttpRequest, HttpResponse, Responder};

use sqlx::PgPool;

#[get("/disable")]
async fn disable(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    match retrieve_claims_for_token(req, secret.to_string()) {
        Ok(claims) => {
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
                claims.jti,
            )
            .fetch_optional(&mut *transaction)
            .await;

            let mut user = match existing_user {
                Ok(existing_user) => {
                    if let Some(user) = existing_user {
                        user
                    } else {
                        return HttpResponse::NotFound().json(GenericResponse {
                            status: "fail".to_string(),
                            message: "No user with this token".to_string(),
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

            if (transaction.commit().await).is_err() {
                return HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to commit transaction".to_string(),
                });
            }

            match updated_user_result {
                Ok(_) => HttpResponse::Ok().json(DisableOtpResponse {
                    status: "success".to_string(),
                    two_fa_enabled: false,
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
