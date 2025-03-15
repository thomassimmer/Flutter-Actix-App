use crate::core::helpers::mock_now::now;
use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::token::generate_tokens;
use crate::features::auth::structs::models::UserToken;
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

    let jti = Uuid::new_v4().to_string();
    let (access_token, refresh_token, claim) = generate_tokens(secret.as_bytes(), jti);

    let refresh_token_expires_at = now()
        .checked_add_signed(chrono::Duration::days(7)) // Access token expires in 15 minutes
        .expect("invalid timestamp");

    let new_token = UserToken {
        id: Uuid::new_v4(),
        user_id: user.id,
        token_id: claim.jti,
        expires_at: refresh_token_expires_at,
    };

    // Insert the new user token into the database
    let insert_result = sqlx::query!(
        r#"
        INSERT INTO user_tokens (id, user_id, token_id, expires_at)
        VALUES ($1, $2, $3, $4)
        "#,
        new_token.id,
        new_token.user_id,
        new_token.token_id,
        new_token.expires_at,
    )
    .execute(&mut *transaction)
    .await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to commit transaction".to_string(),
        });
    }

    if insert_result.is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to insert user token into the database".to_string(),
        });
    }

    HttpResponse::Ok().json(UserLoginResponse {
        status: "success".to_string(),
        access_token,
        refresh_token,
        expires_in: claim.exp,
    })
}
