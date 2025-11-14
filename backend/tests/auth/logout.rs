use actix_http::Request;
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::{self, ContentType};
use actix_web::{test, Error};
use flutteractixapp::core::structs::responses::GenericResponse;
use flutteractixapp::features::auth::application::dto::RefreshTokenRequest;
use sqlx::PgPool;

use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

pub async fn user_logs_out(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    access_token: &str,
) {
    let req = test::TestRequest::get()
        .uri("/api/auth/logout")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "LOGGED_OUT");
}

#[sqlx::test]
async fn user_can_logout(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, _) = user_signs_up(&app).await;

    user_logs_out(&app, &access_token).await;
}

#[sqlx::test]
async fn user_cannot_use_access_token_or_refresh_token_after_logout(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, refresh_token, _) = user_signs_up(&app).await;

    user_has_access_to_protected_route(&app, &access_token).await;

    user_logs_out(&app, &access_token).await;

    let req = test::TestRequest::default()
        .uri("/api/users/me")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let profile_response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(profile_response.code, "INVALID_ACCESS_TOKEN");

    let refresh_request = RefreshTokenRequest {
        refresh_token: refresh_token.to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/refresh-token")
        .insert_header(ContentType::json())
        .set_json(&refresh_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let profile_response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(profile_response.code, "INVALID_REFRESH_TOKEN");
}
