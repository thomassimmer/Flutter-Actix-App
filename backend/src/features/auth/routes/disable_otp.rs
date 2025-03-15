use crate::core::constants::errors::AppError;
use crate::features::auth::structs::responses::DisableOtpResponse;
use crate::features::profile::structs::models::User;

use actix_web::{get, web, HttpResponse, Responder};

use sqlx::PgPool;

#[get("/disable")]
async fn disable(pool: web::Data<PgPool>, mut request_user: User) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response())
        }
    };

    request_user.otp_verified = false;
    request_user.otp_auth_url = None;
    request_user.otp_base32 = None;

    let updated_user_result = sqlx::query_scalar!(
        r#"
        UPDATE users
        SET otp_verified = $1, otp_auth_url = $2, otp_base32 = $3
        WHERE id = $4
        "#,
        request_user.otp_verified,
        request_user.otp_auth_url,
        request_user.otp_base32,
        request_user.id
    )
    .fetch_optional(&mut *transaction)
    .await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(DisableOtpResponse {
            code: "OTP_DISABLED".to_string(),
            two_fa_enabled: false,
        }),
        Err(_) => HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response()),
    }
}
