use crate::features::profile::helpers::profile::{get_user_by_id, update_user};
use crate::{core::constants::errors::AppError, features::auth::structs::models::Claims};

use crate::features::auth::structs::requests::VerifyOtpRequest;
use crate::features::auth::structs::responses::VerifyOtpResponse;

use actix_web::{
    post,
    web::{self, ReqData},
    HttpResponse, Responder,
};

use sqlx::PgPool;
use totp_rs::{Algorithm, Secret, TOTP};
use tracing::error;

#[post("/verify")]
pub async fn verify(
    body: web::Json<VerifyOtpRequest>,
    pool: web::Data<PgPool>,
    request_claims: ReqData<Claims>,
) -> impl Responder {
    let mut request_user = match get_user_by_id(&**pool, request_claims.user_id).await {
        Ok(user) => match user {
            Some(user) => user,
            None => return HttpResponse::NotFound().json(AppError::UserNotFound.to_response()),
        },
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response());
        }
    };

    let otp_base32 = request_user.otp_base32.to_owned().unwrap();
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

    request_user.otp_verified = true;

    let updated_user_result = update_user(&**pool, &request_user).await;

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(VerifyOtpResponse {
            code: "OTP_VERIFIED".to_string(),
            otp_verified: true,
        }),
        Err(e) => {
            error!("Error: {}", e);
            HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response())
        }
    }
}
