use crate::{
    core::constants::errors::AppError,
    features::{
        auth::structs::models::Claims,
        profile::{helpers::profile::get_user, structs::responses::UserResponse},
    },
};
use actix_web::{
    get,
    web::{self, ReqData},
    HttpResponse, Responder,
};
use sqlx::PgPool;

#[get("/me")]
pub async fn get_profile_information(
    request_claims: ReqData<Claims>,
    pool: web::Data<PgPool>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseTransaction.to_response());
        }
    };

    let user = get_user(request_claims.user_id, &mut transaction).await;

    match user {
        Ok(existing_user) => match existing_user {
            Some(user) => HttpResponse::Ok().json(UserResponse {
                code: "PROFILE_FETCHED".to_string(),
                user: user.to_user_data(),
            }),
            None => HttpResponse::NotFound().json(AppError::UserNotFound.to_response()),
        },
        Err(_) => HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response()),
    }
}
