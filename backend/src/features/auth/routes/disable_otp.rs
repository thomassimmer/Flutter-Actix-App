use crate::features::auth::structs::responses::DisableOtpResponse;
use crate::features::profile::helpers::profile::{get_user_by_id, update_user};
use crate::{core::constants::errors::AppError, features::auth::structs::models::Claims};

use actix_web::{
    get,
    web::{self, ReqData},
    HttpResponse, Responder,
};

use sqlx::PgPool;
use tracing::error;

#[get("/disable")]
async fn disable(pool: web::Data<PgPool>, request_claims: ReqData<Claims>) -> impl Responder {
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

    request_user.otp_verified = false;
    request_user.otp_auth_url = None;
    request_user.otp_base32 = None;

    let updated_user_result = update_user(&**pool, &request_user).await;

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(DisableOtpResponse {
            code: "OTP_DISABLED".to_string(),
            two_fa_enabled: false,
        }),
        Err(e) => {
            error!("Error: {}", e);
            HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response())
        }
    }
}
