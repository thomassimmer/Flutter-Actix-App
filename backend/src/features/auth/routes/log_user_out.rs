use crate::core::constants::errors::AppError;
use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::token::delete_token;
use crate::features::auth::structs::models::{Claims, TokenCache};
use actix_web::web::ReqData;
use actix_web::{get, web, HttpResponse, Responder};
use sqlx::PgPool;
use tracing::error;

#[get("")]
pub async fn log_user_out(
    request_claims: ReqData<Claims>,
    pool: web::Data<PgPool>,
    cached_tokens: web::Data<TokenCache>,
) -> impl Responder {
    if let Err(e) = delete_token(&**pool, request_claims.jti).await {
        error!("Error: {}", e);
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    cached_tokens.remove_key(request_claims.jti).await;

    HttpResponse::Ok().json(GenericResponse {
        code: "LOGGED_OUT".to_string(),
        message: "".to_string(),
    })
}
