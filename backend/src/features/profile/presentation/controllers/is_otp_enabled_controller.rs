use actix_web::{post, web, HttpResponse, Responder};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::profile::application::dto::IsOtpEnabledRequest;
use crate::features::profile::application::usecases::IsOtpEnabledUseCase;

#[post("/is-otp-enabled")]
pub async fn is_otp_enabled(
    body: web::Json<IsOtpEnabledRequest>,
    use_case: web::Data<IsOtpEnabledUseCase>,
) -> impl Responder {
    let body = body.into_inner();

    match use_case.execute(body).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Is OTP enabled error: {}", e);
            let error_response = GenericResponse {
                code: "OTP_STATUS_ERROR".to_string(),
                message: "Failed to check OTP status".to_string(),
            };
            HttpResponse::InternalServerError().json(error_response)
        }
    }
}

