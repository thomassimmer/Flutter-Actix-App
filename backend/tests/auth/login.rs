use actix_http::Request;
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::ContentType;
use actix_web::{test, Error};
use flutteractixapp::core::structs::responses::GenericResponse;
use flutteractixapp::features::auth::application::dto::{LoginRequest, LoginResponse};
use sqlx::PgPool;

use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

pub async fn user_logs_in(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    username: &str,
    password: &str,
) -> (String, String) {
    let login_request = LoginRequest {
        username: username.to_string(),
        password: password.to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&login_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: LoginResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_LOGGED_IN_WITHOUT_OTP");

    (response.access_token, response.refresh_token)
}

#[sqlx::test]
async fn user_can_login(pool: PgPool) {
    let app = spawn_app(pool).await;
    user_signs_up(&app).await;
    user_logs_in(&app, "testusername", "password1_").await;
}

#[sqlx::test]
async fn user_cannot_login_with_wrong_password(pool: PgPool) {
    let app = spawn_app(pool).await;
    user_signs_up(&app).await;

    let login_request = LoginRequest {
        username: "testusername".to_string(),
        password: "wrong_password".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&login_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_USERNAME_OR_PASSWORD");
}

#[sqlx::test]
async fn user_cannot_login_with_wrong_username(pool: PgPool) {
    let app = spawn_app(pool).await;
    user_signs_up(&app).await;

    let login_request = LoginRequest {
        username: "wrong_username".to_string(),
        password: "password1_".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&login_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_USERNAME_OR_PASSWORD");
}

#[sqlx::test]
async fn logged_in_user_can_access_profile_information(pool: PgPool) {
    let app = spawn_app(pool).await;
    user_signs_up(&app).await;

    let (access_token, _) = user_logs_in(&app, "testusername", "password1_").await;

    // User can access a route protected by token authentication
    user_has_access_to_protected_route(&app, &access_token).await;
}
