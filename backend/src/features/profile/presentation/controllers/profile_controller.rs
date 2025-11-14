use actix_web::{get, post, web, web::ReqData, HttpResponse, Responder};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::domain::entities::Claims;
use crate::features::profile::application::dto::UpdateProfileRequest;
use crate::features::profile::application::usecases::{GetProfileUseCase, UpdateProfileUseCase};

#[get("/me")]
pub async fn get_profile(
    request_claims: ReqData<Claims>,
    use_case: web::Data<GetProfileUseCase>,
) -> impl Responder {
    match use_case.execute(request_claims.user_id).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Get profile error: {}", e);
            let error_response = match e {
                crate::features::profile::domain::errors::ProfileDomainError::UserNotFound => {
                    GenericResponse {
                        code: "USER_NOT_FOUND".to_string(),
                        message: "User not found".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "PROFILE_FETCH_ERROR".to_string(),
                    message: "Failed to fetch profile".to_string(),
                },
            };
            HttpResponse::NotFound().json(error_response)
        }
    }
}

#[post("/me")]
pub async fn update_profile(
    body: web::Json<UpdateProfileRequest>,
    request_claims: ReqData<Claims>,
    use_case: web::Data<UpdateProfileUseCase>,
) -> impl Responder {
    match use_case.execute(request_claims.user_id, body.into_inner()).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Update profile error: {}", e);
            HttpResponse::InternalServerError().json(GenericResponse {
                code: "PROFILE_UPDATE_ERROR".to_string(),
                message: "Failed to update profile".to_string(),
            })
        }
    }
}

