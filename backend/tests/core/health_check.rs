use actix_web::test;
use flutteractixapp::core::structs::responses::GenericResponse;
use sqlx::PgPool;

use crate::helpers::spawn_app;

#[sqlx::test]
async fn health_check(pool: PgPool) {
    let app = spawn_app(pool).await;

    let req = test::TestRequest::get()
        .uri("/api/health_check")
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "SERVER_IS_RUNNING");
}
