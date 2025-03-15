use crate::features::auth::structs::responses::DisableOtpResponse;
use crate::features::profile::helpers::profile::get_user;
use crate::{core::constants::errors::AppError, features::auth::structs::models::Claims};

use actix_web::{
    get,
    web::{self, ReqData},
    HttpResponse, Responder,
};

use sqlx::PgPool;

#[get("/disable")]
async fn disable(pool: web::Data<PgPool>, request_claims: ReqData<Claims>) -> impl Responder {
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
