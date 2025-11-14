use actix_web::{post, web, web::ReqData, HttpResponse, Responder};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::domain::entities::Claims;
use crate::features::profile::application::dto::{SetPasswordRequest, UpdatePasswordRequest};
use crate::features::profile::application::usecases::{SetPasswordUseCase, UpdatePasswordUseCase};

#[post("/set-password")]
pub async fn set_password(
    body: web::Json<SetPasswordRequest>,
    request_claims: ReqData<Claims>,
    use_case: web::Data<SetPasswordUseCase>,
) -> impl Responder {
    match use_case.execute(request_claims.user_id, body.into_inner()).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Set password error: {}", e);
            let error_response = match e {
                crate::features::profile::domain::errors::ProfileDomainError::PasswordNotExpired => {
                    GenericResponse {
                        code: "PASSWORD_NOT_EXPIRED".to_string(),
                        message: "Password is not expired. You cannot set it here.".to_string(),
                    }
                }
                crate::features::profile::domain::errors::ProfileDomainError::InvalidPassword => {
                    GenericResponse {
                        code: "PASSWORD_TOO_SHORT".to_string(),
                        message: "This password is too short or too weak".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "PASSWORD_SET_ERROR".to_string(),
                    message: "Failed to set password".to_string(),
                },
            };
            HttpResponse::Forbidden().json(error_response)
        }
    }
}

#[post("/update-password")]
pub async fn update_password(
    body: web::Json<UpdatePasswordRequest>,
    request_claims: ReqData<Claims>,
    use_case: web::Data<UpdatePasswordUseCase>,
) -> impl Responder {
    match use_case.execute(request_claims.user_id, body.into_inner()).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Update password error: {}", e);
            let error_response = match e {
                crate::features::profile::domain::errors::ProfileDomainError::InvalidPassword => {
                    GenericResponse {
                        code: "INVALID_USERNAME_OR_PASSWORD".to_string(),
                        message: "Invalid username or password".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "PASSWORD_UPDATE_ERROR".to_string(),
                    message: "Failed to update password".to_string(),
                },
            };
            HttpResponse::Unauthorized().json(error_response)
        }
    }
}

