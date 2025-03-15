use crate::{
    core::constants::errors::AppError,
    features::{
        auth::structs::models::Claims,
        profile::{helpers::profile::get_user_by_id, structs::responses::UserResponse},
    },
};
use actix_web::{
    get,
    web::{self, ReqData},
    HttpResponse, Responder,
};
use sqlx::PgPool;
use tracing::error;

#[get("/me")]
pub async fn get_profile_information(
    request_claims: ReqData<Claims>,
    pool: web::Data<PgPool>,
) -> impl Responder {
    let user = get_user_by_id(&**pool, request_claims.user_id).await;

    match user {
        Ok(existing_user) => match existing_user {
            Some(user) => HttpResponse::Ok().json(UserResponse {
                code: "PROFILE_FETCHED".to_string(),
                user: user.to_user_data(),
            }),
            None => HttpResponse::NotFound().json(AppError::UserNotFound.to_response()),
        },
        Err(e) => {
            error!("Error: {}", e);
            HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response())
        }
    }
}
