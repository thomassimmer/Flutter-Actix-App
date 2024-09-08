use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::token::generate_tokens;
use crate::features::auth::structs::requests::ValidateOtpRequest;
use crate::features::auth::structs::responses::UserLoginResponse;
use crate::features::profile::structs::models::User;

use actix_web::{post, web, HttpResponse, Responder};

use sqlx::PgPool;
use totp_rs::{Algorithm, Secret, TOTP};
use uuid::Uuid;

#[post("/validate")]
async fn validate(
    body: web::Json<ValidateOtpRequest>,
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
    let user_id = Uuid::parse_str(&body.user_id).unwrap();

    // Check if user already exists
    let existing_user = sqlx::query_as!(
        User,
        r#"
        SELECT *
        FROM users
        WHERE id = $1
        "#,
        user_id,
    )
    .fetch_optional(&mut *transaction)
    .await;

    let user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::NotFound().json(GenericResponse {
                    status: "fail".to_string(),
                    message: format!("No user with id: {} found", body.user_id),
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

    if !user.otp_verified {
        let json_error = GenericResponse {
            status: "fail".to_string(),
            message: "2FA not enabled".to_string(),
        };

        return HttpResponse::Forbidden().json(json_error);
    }

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
        return HttpResponse::Forbidden().json(GenericResponse {
            status: "fail".to_string(),
            message: "Token is invalid or user doesn't exist".to_string(),
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
