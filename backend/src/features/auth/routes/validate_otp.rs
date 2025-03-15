use crate::core::{constants::errors::AppError, structs::responses::GenericResponse};
use crate::features::auth::helpers::token::generate_tokens;
use crate::features::auth::structs::requests::ValidateOtpRequest;
use crate::features::auth::structs::responses::UserLoginResponse;
use crate::features::profile::helpers::device_info::get_user_agent;
use crate::features::profile::helpers::profile::get_user_by_id;

use actix_web::{post, web, HttpRequest, HttpResponse, Responder};

use sqlx::PgPool;
use totp_rs::{Algorithm, Secret, TOTP};
use tracing::error;

#[post("/validate")]
async fn validate(
    req: HttpRequest,
    body: web::Json<ValidateOtpRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let body = body.into_inner();
    let user_id = body.user_id;

    let existing_user = get_user_by_id(&**pool, user_id).await;

    let user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::NotFound().json(GenericResponse {
                    code: "USER_NOT_FOUND".to_string(),
                    message: format!("No user with id {} found", body.user_id),
                });
            }
        }
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError().json(AppError::DatabaseQuery.to_response());
        }
    };

    if !user.otp_verified {
        return HttpResponse::Forbidden()
            .json(AppError::TwoFactorAuthenticationNotEnabled.to_response());
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
        return HttpResponse::Unauthorized().json(AppError::InvalidOneTimePassword.to_response());
    }

    let parsed_device_info = get_user_agent(req).await;

    let (access_token, refresh_token) = match generate_tokens(
        &**pool,
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

    HttpResponse::Ok().json(UserLoginResponse {
        code: "USER_LOGGED_IN_AFTER_OTP_VALIDATION".to_string(),
        access_token,
        refresh_token,
    })
}
