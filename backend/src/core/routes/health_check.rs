use actix_web::{HttpResponse, Responder};
use serde_json::json;

pub async fn health_check() -> impl Responder {
    const MESSAGE: &str = "Server is running fine";

    HttpResponse::Ok().json(json!({"status": "success", "message": MESSAGE}))
}
