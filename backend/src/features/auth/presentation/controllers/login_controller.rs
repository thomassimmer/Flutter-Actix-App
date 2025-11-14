use actix_web::{post, web, HttpRequest, HttpResponse, Responder};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::application::dto::LoginRequest;
use crate::features::auth::application::usecases::LoginUseCase;
use crate::features::auth::domain::entities::DeviceInfo;
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

#[post("/login")]
pub async fn login(
    req: HttpRequest,
    body: web::Json<LoginRequest>,
    use_case: web::Data<LoginUseCase>,
) -> impl Responder {
    let body = body.into_inner();
    let parsed_device_info = get_user_agent(req).await;
    let device_info = parse_device_info_to_domain(parsed_device_info);

    match use_case.execute(body, device_info).await {
        Ok(Ok(response)) => HttpResponse::Ok().json(response),
        Ok(Err(response)) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Login error: {}", e);
            let (status_code, error_response) = match e {
                crate::features::auth::domain::errors::AuthDomainError::InvalidCredentials => {
                    (
                        actix_web::http::StatusCode::UNAUTHORIZED,
                        GenericResponse {
                            code: "INVALID_USERNAME_OR_PASSWORD".to_string(),
                            message: "Invalid username or password".to_string(),
                        },
                    )
                }
                crate::features::auth::domain::errors::AuthDomainError::PasswordExpired => {
                    (
                        actix_web::http::StatusCode::FORBIDDEN,
                        GenericResponse {
                            code: "PASSWORD_MUST_BE_CHANGED".to_string(),
                            message: "Password must be changed".to_string(),
                        },
                    )
                }
                _ => (
                    actix_web::http::StatusCode::UNAUTHORIZED,
                    GenericResponse {
                        code: "LOGIN_ERROR".to_string(),
                        message: "Failed to log in".to_string(),
                    },
                ),
            };
            HttpResponse::build(status_code).json(error_response)
        }
    }
}

