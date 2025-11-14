use actix_web::{get, web, web::ReqData, HttpResponse, Responder};
use tracing::error;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::application::usecases::LogoutUseCase;
use crate::features::auth::domain::entities::Claims;

#[get("")]
pub async fn logout(
    request_claims: ReqData<Claims>,
    use_case: web::Data<LogoutUseCase>,
) -> impl Responder {
    match use_case.execute(request_claims.jti).await {
        Ok(_) => HttpResponse::Ok().json(GenericResponse {
            code: "LOGGED_OUT".to_string(),
            message: "".to_string(),
        }),
        Err(e) => {
            error!("Logout error: {}", e);
            HttpResponse::InternalServerError().json(GenericResponse {
                code: "LOGOUT_ERROR".to_string(),
                message: "Failed to log out".to_string(),
            })
        }
    }
}

