use crate::{
    core::constants::errors::AppError,
    features::{
        auth::structs::models::Claims,
        profile::{
            helpers::profile::{get_user_by_id, update_user},
            structs::{requests::UserUpdateRequest, responses::UserResponse},
        },
    },
};
use actix_web::{
    post,
    web::{self, ReqData},
    HttpResponse, Responder,
};
use sqlx::PgPool;
use tracing::error;

#[post("/me")]
pub async fn post_profile_information(
    body: web::Json<UserUpdateRequest>,
    pool: web::Data<PgPool>,
    request_claims: ReqData<Claims>,
) -> impl Responder {
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

    request_user.username = body.username.clone();
    request_user.locale = body.locale.clone();
    request_user.theme = body.theme.clone();

    let updated_user_result = update_user(&**pool, &request_user).await;

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(UserResponse {
            code: "PROFILE_UPDATED".to_string(),
            user: request_user.to_user_data(),
        }),
        Err(e) => {
            error!("Error: {}", e);
            HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response())
        }
    }
}
