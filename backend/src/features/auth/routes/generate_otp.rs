use crate::features::auth::structs::responses::GenerateOtpResponse;
use crate::features::profile::helpers::profile::get_user;
use crate::{core::constants::errors::AppError, features::auth::structs::models::Claims};

use actix_web::{
    get,
    web::{self, ReqData},
    HttpResponse, Responder,
};

use base32;
use rand::Rng;
use sqlx::PgPool;
use totp_rs::{Algorithm, Secret, TOTP};
use tracing::error;

#[get("/generate")]
pub async fn generate(pool: web::Data<PgPool>, request_claims: ReqData<Claims>) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response());
        }
    };

    let mut request_user = match get_user(request_claims.user_id, &mut transaction).await {
        Ok(user) => match user {
            Some(user) => user,
            None => return HttpResponse::NotFound().json(AppError::UserNotFound.to_response()),
        },
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response());
        }
    };

    let mut rng = rand::thread_rng();
    let data_byte: [u8; 21] = rng.gen();
    let base32_string = base32::encode(base32::Alphabet::Rfc4648 { padding: false }, &data_byte);

    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(base32_string).to_bytes().unwrap(),
    )
    .unwrap();

    let otp_base32 = totp.get_secret_base32();
    let username = request_user.username.to_owned();
    let issuer = "Flutter Actix App";

    // Format should be:
    // let otp_auth_url = format!("otpauth://totp/<issuer>:<account_name>?secret=<secret>&issuer=<issuer>");
    let otp_auth_url =
        format!("otpauth://totp/{issuer}:{username}?secret={otp_base32}&issuer={issuer}");

    request_user.otp_base32 = Some(otp_base32.to_owned());
    request_user.otp_auth_url = Some(otp_auth_url.to_owned());
    request_user.otp_verified = false;

    let updated_user_result = sqlx::query!(
        r#"
        UPDATE users
        SET otp_base32 = $1, otp_auth_url = $2, otp_verified = $3
        WHERE id = $4
        "#,
        request_user.otp_base32,
        request_user.otp_auth_url,
        request_user.otp_verified,
        request_user.id
    )
    .fetch_optional(&mut *transaction)
    .await;

    if let Err(e) = transaction.commit().await {
        error!("Error: {}", e);
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(GenerateOtpResponse {
            code: "OTP_GENERATED".to_string(),
            otp_base32: otp_base32.to_owned(),
            otp_auth_url: otp_auth_url.to_owned(),
        }),
        Err(e) => {
            error!("Error: {}", e);
            HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response())
        }
    }
}
