use std::time::Duration;

use actix_http::Request;
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::{self, ContentType};
use actix_web::{test, Error};
use chrono::Utc;
use flutteractixapp::core::helpers::mock_now::override_now;
use flutteractixapp::core::structs::responses::GenericResponse;
use flutteractixapp::features::auth::structs::responses::RefreshTokenResponse;

use crate::auth::login::user_logs_in;
use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

pub async fn user_refreshes_token(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    refresh_token: &str,
) -> String {
    let req = test::TestRequest::post()
        .uri("/api/auth/refresh-token")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "refresh_token": refresh_token,
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: RefreshTokenResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "TOKEN_REFRESHED");

    response.access_token
}

#[tokio::test]
async fn user_can_refresh_token() {
    let app = spawn_app().await;
    user_signs_up(&app).await;
    let (_, refresh_token) = user_logs_in(&app, "testusername", "password1_").await;
    let access_token = user_refreshes_token(&app, &refresh_token).await;

    user_has_access_to_protected_route(&app, &access_token).await;
}

#[tokio::test]
async fn user_cannot_refresh_using_a_wrong_refresh_token() {
    let app = spawn_app().await;
    user_signs_up(&app).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/refresh-token")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "refresh_token": "wrong token",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_REFRESH_TOKEN");
}

#[tokio::test]
async fn access_token_becomes_expired_after_15_minutes() {
    let app = spawn_app().await;

    let (access_token, _, _) = user_signs_up(&app).await;

    user_has_access_to_protected_route(&app, &access_token).await;

    override_now(Some(
        (Utc::now() + Duration::new(14 * 60, 1)).fixed_offset(),
    ));

    // After 14 minutes, user can still access protected route
    user_has_access_to_protected_route(&app, &access_token).await;

    override_now(Some(
        (Utc::now() + Duration::new(15 * 60, 1)).fixed_offset(),
    ));

    // After 15 minutes, user cannot access protected route anymore
    let req = test::TestRequest::default()
        .uri("/api/users/me")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let profile_response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(profile_response.code, "ACCESS_TOKEN_EXPIRED");
}

#[tokio::test]
async fn refresh_token_becomes_expired_after_7_days() {
    let app = spawn_app().await;
    user_signs_up(&app).await;
    let (_, refresh_token) = user_logs_in(&app, "testusername", "password1_").await;

    let access_token = user_refreshes_token(&app, &refresh_token).await;
    user_has_access_to_protected_route(&app, &access_token).await;

    // After 6 days, user can still refresh its access_token
    override_now(Some(
        (Utc::now() + Duration::new(60 * 60 * 24 * 6, 1)).fixed_offset(),
    ));

    let access_token = user_refreshes_token(&app, &refresh_token).await;
    user_has_access_to_protected_route(&app, &access_token).await;

    // After 7 days, user can still refresh its access_token
    override_now(Some(
        (Utc::now() + Duration::new(60 * 60 * 24 * 7, 1)).fixed_offset(),
    ));

    let req = test::TestRequest::post()
        .uri("/api/auth/refresh-token")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "refresh_token": refresh_token,
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let profile_response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(profile_response.code, "REFRESH_TOKEN_EXPIRED");
}
