use actix_web::{post, web, HttpRequest, HttpResponse, Responder};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::application::dto::RefreshTokenRequest;
use crate::features::auth::application::usecases::RefreshTokenUseCase;
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

#[post("/refresh-token")]
pub async fn refresh_token(
    req: HttpRequest,
    body: web::Json<RefreshTokenRequest>,
    use_case: web::Data<RefreshTokenUseCase>,
) -> impl Responder {
    let parsed_device_info = get_user_agent(req).await;
    let device_info = parse_device_info_to_domain(parsed_device_info);

    match use_case.execute(body.into_inner(), device_info).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Refresh token error: {}", e);
            let error_response = match e {
                crate::features::auth::domain::errors::AuthDomainError::TokenExpired => {
                    GenericResponse {
                        code: "REFRESH_TOKEN_EXPIRED".to_string(),
                        message: "Refresh token expired".to_string(),
                    }
                }
                crate::features::auth::domain::errors::AuthDomainError::InvalidToken => {
                    GenericResponse {
                        code: "INVALID_REFRESH_TOKEN".to_string(),
                        message: "Invalid refresh token".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "REFRESH_TOKEN_ERROR".to_string(),
                    message: "Failed to refresh token".to_string(),
                },
            };
            HttpResponse::Unauthorized().json(error_response)
        }
    }
}

