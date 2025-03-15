use crate::features::profile::helpers::profile::get_user;
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

#[post("/verify")]
pub async fn verify(
    body: web::Json<VerifyOtpRequest>,
    pool: web::Data<PgPool>,
    request_claims: ReqData<Claims>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response())
        }
    };

    let mut request_user = match get_user(request_claims.user_id, &mut transaction).await {
        Ok(user) => match user {
            Some(user) => user,
            None => return HttpResponse::NotFound().json(AppError::UserNotFound.to_response()),
        },
        Err(_) => {
            return HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response())
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

    let updated_user_result = sqlx::query_scalar!(
        r#"
        UPDATE users
        SET otp_verified = $1
        WHERE id = $2
        "#,
        request_user.otp_verified,
        request_user.id
    )
    .fetch_optional(&mut *transaction)
    .await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(VerifyOtpResponse {
            code: "OTP_VERIFIED".to_string(),
            otp_verified: true,
        }),
        Err(_) => HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response()),
    }
}
