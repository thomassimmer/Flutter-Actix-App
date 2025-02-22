use crate::{
    core::constants::errors::AppError,
    features::{
        auth::{
            helpers::token::get_user_tokens,
            structs::models::{Claims, TokenCache},
        },
        profile::structs::{
            models::ParsedDeviceInfo,
            responses::{DeviceData, DevicesResponse},
        },
    },
};
use actix_web::{
    get,
    web::{self, ReqData},
    HttpResponse, Responder,
};
use sqlx::PgPool;

#[get("/")]
pub async fn get_devices(
    claims: ReqData<Claims>,
    pool: web::Data<PgPool>,
    cached_tokens: web::Data<TokenCache>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response())
        }
    };

    let tokens = get_user_tokens(claims.user_id, &mut transaction).await;

    if tokens.is_err() {
        return HttpResponse::InternalServerError().json(AppError::DatabaseQuery.to_response());
    }

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    let mut devices = Vec::new();

    for token in tokens.unwrap() {
        devices.push(DeviceData {
            token_id: token.token_id,
            parsed_device_info: ParsedDeviceInfo {
                os: token.os,
                is_mobile: token.is_mobile,
                browser: token.browser,
                app_version: token.app_version,
                model: token.model
            },
            last_activity_date: cached_tokens.get_value_for_key(token.token_id).await,
        });
    }

    HttpResponse::Ok().json(DevicesResponse {
        code: "DEVICES_FETCHED".to_string(),
        devices,
    })
}
