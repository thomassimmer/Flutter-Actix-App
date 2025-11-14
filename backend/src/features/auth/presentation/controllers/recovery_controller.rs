use actix_web::{post, web, HttpRequest, HttpResponse, Responder};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::application::dto::{
    RecoverAccountUsing2FARequest, RecoverAccountUsingPasswordRequest,
    RecoverAccountWithout2FAEnabledRequest,
};
use crate::features::auth::application::usecases::{
    RecoverAccountUsing2FAUseCase, RecoverAccountUsingPasswordUseCase,
    RecoverAccountWithout2FAEnabledUseCase,
};
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

#[post("/recover")]
pub async fn recover_account_without_2fa_enabled(
    req: HttpRequest,
    body: web::Json<RecoverAccountWithout2FAEnabledRequest>,
    use_case: web::Data<RecoverAccountWithout2FAEnabledUseCase>,
) -> impl Responder {
    let body = body.into_inner();
    let parsed_device_info = get_user_agent(req).await;
    let device_info = parse_device_info_to_domain(parsed_device_info);

    match use_case.execute(body, device_info).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Recover account without 2FA error: {}", e);
            let error_response = match e {
                crate::features::auth::domain::errors::AuthDomainError::InvalidUsernameOrRecoveryCode => {
                    GenericResponse {
                        code: "INVALID_USERNAME_OR_RECOVERY_CODE".to_string(),
                        message: "Invalid username or recovery code".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "RECOVERY_ERROR".to_string(),
                    message: "Failed to recover account".to_string(),
                },
            };
            HttpResponse::Unauthorized().json(error_response)
        }
    }
}

#[post("/recover-using-password")]
pub async fn recover_account_using_password(
    req: HttpRequest,
    body: web::Json<RecoverAccountUsingPasswordRequest>,
    use_case: web::Data<RecoverAccountUsingPasswordUseCase>,
) -> impl Responder {
    let body = body.into_inner();
    let parsed_device_info = get_user_agent(req).await;
    let device_info = parse_device_info_to_domain(parsed_device_info);

    match use_case.execute(body, device_info).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Recover account using password error: {}", e);
            let error_response = match e {
                crate::features::auth::domain::errors::AuthDomainError::TwoFactorAuthenticationNotEnabled => {
                    GenericResponse {
                        code: "TWO_FACTOR_AUTHENTICATION_NOT_ENABLED".to_string(),
                        message: "Two-factor authentication is not enabled".to_string(),
                    }
                }
                crate::features::auth::domain::errors::AuthDomainError::InvalidUsernameOrPasswordOrRecoveryCode => {
                    GenericResponse {
                        code: "INVALID_USERNAME_OR_PASSWORD_OR_RECOVERY_CODE".to_string(),
                        message: "Invalid username, password, or recovery code".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "RECOVERY_ERROR".to_string(),
                    message: "Failed to recover account".to_string(),
                },
            };
            let status_code = if matches!(
                e,
                crate::features::auth::domain::errors::AuthDomainError::TwoFactorAuthenticationNotEnabled
            ) {
                actix_web::http::StatusCode::FORBIDDEN
            } else {
                actix_web::http::StatusCode::UNAUTHORIZED
            };
            HttpResponse::build(status_code).json(error_response)
        }
    }
}

#[post("/recover-using-2fa")]
pub async fn recover_account_using_2fa(
    req: HttpRequest,
    body: web::Json<RecoverAccountUsing2FARequest>,
    use_case: web::Data<RecoverAccountUsing2FAUseCase>,
) -> impl Responder {
    let body = body.into_inner();
    let parsed_device_info = get_user_agent(req).await;
    let device_info = parse_device_info_to_domain(parsed_device_info);

    match use_case.execute(body, device_info).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Recover account using 2FA error: {}", e);
            let error_response = match e {
                crate::features::auth::domain::errors::AuthDomainError::TwoFactorAuthenticationNotEnabled => {
                    GenericResponse {
                        code: "TWO_FACTOR_AUTHENTICATION_NOT_ENABLED".to_string(),
                        message: "Two-factor authentication is not enabled".to_string(),
                    }
                }
                crate::features::auth::domain::errors::AuthDomainError::InvalidUsernameOrCodeOrRecoveryCode => {
                    GenericResponse {
                        code: "INVALID_USERNAME_OR_CODE_OR_RECOVERY_CODE".to_string(),
                        message: "Invalid username, code, or recovery code".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "RECOVERY_ERROR".to_string(),
                    message: "Failed to recover account".to_string(),
                },
            };
            let status_code = if matches!(
                e,
                crate::features::auth::domain::errors::AuthDomainError::TwoFactorAuthenticationNotEnabled
            ) {
                actix_web::http::StatusCode::FORBIDDEN
            } else {
                actix_web::http::StatusCode::UNAUTHORIZED
            };
            HttpResponse::build(status_code).json(error_response)
        }
    }
}

