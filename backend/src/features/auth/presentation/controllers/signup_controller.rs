use actix_web::{post, web, HttpRequest, HttpResponse, Responder};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::application::dto::SignupRequest;
use crate::features::auth::application::usecases::SignupUseCase;
use crate::features::auth::domain::entities::DeviceInfo;
use crate::features::auth::helpers::password::is_password_valid;
use crate::features::auth::helpers::username::is_username_valid;
use crate::features::profile::helpers::device_info::get_user_agent;
use crate::features::profile::structs::models::ParsedDeviceInfo;

fn parse_device_info_to_domain(parsed: ParsedDeviceInfo) -> DeviceInfo {
    DeviceInfo {
        os: parsed.os,
        is_mobile: parsed.is_mobile,
        browser: parsed.browser,
        app_version: parsed.app_version,
        model: parsed.model,
    }
}

#[post("/signup")]
pub async fn signup(
    req: HttpRequest,
    body: web::Json<SignupRequest>,
    use_case: web::Data<SignupUseCase>,
) -> impl Responder {
    let body = body.into_inner();

    // Validate username
    if let Some(exception) = is_username_valid(&body.username) {
        return HttpResponse::Unauthorized().json(exception.to_response());
    }

    // Validate password
    if let Some(exception) = is_password_valid(&body.password) {
        return HttpResponse::Unauthorized().json(exception.to_response());
    }

    // Parse device info
    let parsed_device_info = get_user_agent(req).await;
    let device_info = parse_device_info_to_domain(parsed_device_info);

    match use_case.execute(body, device_info).await {
        Ok(response) => HttpResponse::Created().json(response),
        Err(e) => {
            error!("Signup error: {}", e);
            // Map domain errors to HTTP responses
            let error_response = match e {
                crate::features::auth::domain::errors::AuthDomainError::UserAlreadyExists => {
                    GenericResponse {
                        code: "USER_ALREADY_EXISTS".to_string(),
                        message: "User with this username already exists".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "SIGNUP_ERROR".to_string(),
                    message: "Failed to sign up user".to_string(),
                },
            };
            let status_code = if matches!(
                e,
                crate::features::auth::domain::errors::AuthDomainError::UserAlreadyExists
            ) {
                actix_web::http::StatusCode::CONFLICT
            } else {
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR
            };
            HttpResponse::build(status_code).json(error_response)
        }
    }
}

