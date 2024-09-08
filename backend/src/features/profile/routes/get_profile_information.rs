use crate::features::profile::structs::{models::User, responses::UserResponse};
use actix_web::{get, HttpResponse, Responder};

#[get("/me")]
pub async fn get_profile_information(request_user: User) -> impl Responder {
    HttpResponse::Ok().json(UserResponse {
        code: "PROFILE_FETCHED".to_string(),
        user: request_user.to_user_data(),
    })
}
