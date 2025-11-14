use actix_web::{
    get, post,
    web::{self, ReqData},
    HttpRequest, HttpResponse, Responder,
};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::application::dto::{ValidateOtpRequest, VerifyOtpRequest};
use crate::features::auth::application::usecases::{
    DisableOtpUseCase, GenerateOtpUseCase, ValidateOtpUseCase, VerifyOtpUseCase,
};
use crate::features::auth::domain::entities::{Claims, DeviceInfo};
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

#[get("/generate")]
pub async fn generate_otp(
    request_claims: ReqData<Claims>,
    use_case: web::Data<GenerateOtpUseCase>,
) -> impl Responder {
    match use_case.execute(request_claims.user_id).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Generate OTP error: {}", e);
            let error_response = match e {
                crate::features::auth::domain::errors::AuthDomainError::UserNotFound => {
                    GenericResponse {
                        code: "USER_NOT_FOUND".to_string(),
                        message: "User not found".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "OTP_GENERATION_ERROR".to_string(),
                    message: "Failed to generate OTP".to_string(),
                },
            };
            HttpResponse::InternalServerError().json(error_response)
        }
    }
}

#[post("/verify")]
pub async fn verify_otp(
    body: web::Json<VerifyOtpRequest>,
    request_claims: ReqData<Claims>,
    use_case: web::Data<VerifyOtpUseCase>,
) -> impl Responder {
    match use_case.execute(request_claims.user_id, body.into_inner()).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Verify OTP error: {}", e);
            let error_response = match e {
                crate::features::auth::domain::errors::AuthDomainError::InvalidOtp => {
                    GenericResponse {
                        code: "INVALID_ONE_TIME_PASSWORD".to_string(),
                        message: "Invalid one time password".to_string(),
                    }
                }
                crate::features::auth::domain::errors::AuthDomainError::OtpNotEnabled => {
                    GenericResponse {
                        code: "TWO_FACTOR_AUTHENTICATION_NOT_ENABLED".to_string(),
                        message: "Two factor authentication is not enabled".to_string(),
                    }
                }
                _ => GenericResponse {
                    code: "OTP_VERIFICATION_ERROR".to_string(),
                    message: "Failed to verify OTP".to_string(),
                },
            };
            HttpResponse::Unauthorized().json(error_response)
        }
    }
}

#[post("/validate")]
pub async fn validate_otp(
    req: HttpRequest,
    body: web::Json<ValidateOtpRequest>,
    use_case: web::Data<ValidateOtpUseCase>,
) -> impl Responder {
    let parsed_device_info = get_user_agent(req).await;
    let device_info = parse_device_info_to_domain(parsed_device_info);

    match use_case.execute(body.into_inner(), device_info).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Validate OTP error: {}", e);
            let (status_code, error_response) = match e {
                crate::features::auth::domain::errors::AuthDomainError::InvalidOtp => {
                    (
                        actix_web::http::StatusCode::UNAUTHORIZED,
                        GenericResponse {
                            code: "INVALID_ONE_TIME_PASSWORD".to_string(),
                            message: "Invalid one time password".to_string(),
                        },
                    )
                }
                crate::features::auth::domain::errors::AuthDomainError::OtpNotEnabled => {
                    (
                        actix_web::http::StatusCode::UNAUTHORIZED,
                        GenericResponse {
                            code: "TWO_FACTOR_AUTHENTICATION_NOT_ENABLED".to_string(),
                            message: "Two factor authentication is not enabled".to_string(),
                        },
                    )
                }
                crate::features::auth::domain::errors::AuthDomainError::UserNotFound => {
                    (
                        actix_web::http::StatusCode::NOT_FOUND,
                        GenericResponse {
                            code: "USER_NOT_FOUND".to_string(),
                            message: "User not found".to_string(),
                        },
                    )
                }
                _ => (
                    actix_web::http::StatusCode::UNAUTHORIZED,
                    GenericResponse {
                        code: "OTP_VALIDATION_ERROR".to_string(),
                        message: "Failed to validate OTP".to_string(),
                    },
                ),
            };
            HttpResponse::build(status_code).json(error_response)
        }
    }
}

#[get("/disable")]
pub async fn disable_otp(
    request_claims: ReqData<Claims>,
    use_case: web::Data<DisableOtpUseCase>,
) -> impl Responder {
    match use_case.execute(request_claims.user_id).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Disable OTP error: {}", e);
            HttpResponse::InternalServerError().json(GenericResponse {
                code: "OTP_DISABLE_ERROR".to_string(),
                message: "Failed to disable OTP".to_string(),
            })
        }
    }
}

