use actix_web::{get, HttpResponse, Responder};

use crate::core::structs::responses::GenericResponse;

#[get("/health_check")]
pub async fn health_check() -> impl Responder {
    const MESSAGE: &str = "Server is running fine";

    HttpResponse::Ok().json(GenericResponse {
        code: "SERVER_IS_RUNNING".to_string(),
        message: MESSAGE.to_string(),
    })
}
