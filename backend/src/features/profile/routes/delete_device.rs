use crate::{
    core::constants::errors::AppError,
    features::{
        auth::{
            helpers::token::{delete_token, get_user_token},
            structs::models::{Claims, TokenCache},
        },
        profile::structs::{requests::DeleteDeviceParams, responses::DeviceDeleteResponse},
    },
};
use actix_web::{
    delete,
    web::{self, ReqData},
    HttpResponse, Responder,
};
use sqlx::PgPool;
use tracing::error;

#[delete("/{token_id}")]
pub async fn delete_device(
    claims: ReqData<Claims>,
    pool: web::Data<PgPool>,
    params: web::Path<DeleteDeviceParams>,
    cached_tokens: web::Data<TokenCache>,
) -> impl Responder {
    let token = get_user_token(&**pool, claims.user_id, params.token_id).await;

    match token {
        Ok(r) => {
            if r.is_none() {
                return HttpResponse::InternalServerError()
                    .json(AppError::DatabaseQuery.to_response());
            }
        }
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError().json(AppError::DatabaseQuery.to_response());
        }
    };

    let result_delete_token = delete_token(&**pool, params.token_id).await;

    if let Err(e) = result_delete_token {
        error!("Error: {}", e);
        return HttpResponse::InternalServerError().json(AppError::DatabaseQuery.to_response());
    }

    cached_tokens.remove_key(claims.jti).await;

    HttpResponse::Ok().json(DeviceDeleteResponse {
        code: "DEVICE_DELETED".to_string(),
    })
}
