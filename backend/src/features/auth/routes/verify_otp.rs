use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::token::retrieve_claims_for_token;

use crate::features::auth::structs::requests::VerifyOtpRequest;
use crate::features::auth::structs::responses::VerifyOtpResponse;
use crate::features::profile::structs::models::User;

use actix_web::{post, web, HttpRequest, HttpResponse, Responder};

use sqlx::PgPool;
use totp_rs::{Algorithm, Secret, TOTP};

#[post("/verify")]
pub async fn verify(
    req: HttpRequest,
    body: web::Json<VerifyOtpRequest>,
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

            let otp_base32 = user.otp_base32.to_owned().unwrap();

            let totp = TOTP::new(
                Algorithm::SHA1,
                6,
                1,
                30,
                Secret::Encoded(otp_base32).to_bytes().unwrap(),
            )
            .unwrap();

            let is_valid = totp.check_current(&body.code).unwrap();

            if !is_valid {
                let json_error = GenericResponse {
                    status: "fail".to_string(),
                    message: "Token is invalid or user doesn't exist".to_string(),
                };

                return HttpResponse::Forbidden().json(json_error);
            }

            user.otp_verified = true;

            let updated_user_result = sqlx::query_scalar!(
                r#"
                UPDATE users
                SET otp_verified = $1
                WHERE id = $2
                "#,
                user.otp_verified,
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
                Ok(_) => HttpResponse::Ok().json(VerifyOtpResponse {
                    status: "success".to_string(),
                    otp_verified: true,
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
