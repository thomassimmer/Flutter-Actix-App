use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::token::retrieve_claims_for_token;
use crate::features::auth::structs::responses::GenerateOtpResponse;
use crate::features::profile::structs::models::User;

use actix_web::{get, web, HttpRequest, HttpResponse, Responder};

use base32;
use rand::Rng;
use sqlx::PgPool;
use totp_rs::{Algorithm, Secret, TOTP};

#[get("/generate")]
pub async fn generate(
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

            let mut rng = rand::thread_rng();
            let data_byte: [u8; 21] = rng.gen();
            let base32_string =
                base32::encode(base32::Alphabet::Rfc4648 { padding: false }, &data_byte);

            let totp = TOTP::new(
                Algorithm::SHA1,
                6,
                1,
                30,
                Secret::Encoded(base32_string).to_bytes().unwrap(),
            )
            .unwrap();

            let otp_base32 = totp.get_secret_base32();
            let username = user.username.to_owned();
            let issuer = "Flutter Actix App";

            // Format should be:
            // let otp_auth_url = format!("otpauth://totp/<issuer>:<account_name>?secret=<secret>&issuer=<issuer>");
            let otp_auth_url =
                format!("otpauth://totp/{issuer}:{username}?secret={otp_base32}&issuer={issuer}");

            user.otp_base32 = Some(otp_base32.to_owned());
            user.otp_auth_url = Some(otp_auth_url.to_owned());
            user.otp_verified = false;

            let updated_user_result = sqlx::query!(
                r#"
                UPDATE users
                SET otp_base32 = $1, otp_auth_url = $2, otp_verified = $3
                WHERE id = $4
                "#,
                user.otp_base32,
                user.otp_auth_url,
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
                Ok(_) => HttpResponse::Ok().json(GenerateOtpResponse {
                    status: "success".to_string(),
                    otp_base32: otp_base32.to_owned(),
                    otp_auth_url: otp_auth_url.to_owned(),
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
