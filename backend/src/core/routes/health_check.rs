use actix_web::{get, HttpResponse, Responder};

use crate::core::structs::response::GenericResponse;

#[get("/health_check")]
pub async fn health_check() -> impl Responder {
    const MESSAGE: &str = "Server is running fine";

    HttpResponse::Ok().json(GenericResponse {
        status: "success".to_string(),
        message: MESSAGE.to_string(),
    })
}
