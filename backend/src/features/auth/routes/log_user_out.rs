use crate::core::constants::errors::AppError;
use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::token::delete_token;
use crate::features::auth::structs::models::{Claims, TokenCache};
use actix_web::web::ReqData;
use actix_web::{get, web, HttpResponse, Responder};
use sqlx::PgPool;

#[get("")]
pub async fn log_user_out(
    request_claims: ReqData<Claims>,
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

    if (delete_token(request_claims.jti, &mut transaction).await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    cached_tokens.remove_key(request_claims.jti).await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    HttpResponse::Ok().json(GenericResponse {
        code: "LOGGED_OUT".to_string(),
        message: "".to_string(),
    })
}
