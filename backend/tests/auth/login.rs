use actix_http::Request;
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::ContentType;
use actix_web::{test, Error};
use flutteractixapp::core::structs::responses::GenericResponse;
use flutteractixapp::features::auth::structs::responses::UserLoginResponse;

use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

pub async fn user_logs_in(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    username: &str,
    password: &str,
) -> (String, String) {
    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
        "username": username,
        "password": password,
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserLoginResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_LOGGED_IN_WITHOUT_OTP");

    (response.access_token, response.refresh_token)
}

#[tokio::test]
async fn user_can_login() {
    let app = spawn_app().await;
    user_signs_up(&app).await;
    user_logs_in(&app, "testusername", "password1_").await;
}

#[tokio::test]
async fn user_cannot_login_with_wrong_password() {
    let app = spawn_app().await;
    user_signs_up(&app).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
        "username": "testusername",
        "password": "wrong_password",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_USERNAME_OR_PASSWORD");
}

#[tokio::test]
async fn user_cannot_login_with_wrong_username() {
    let app = spawn_app().await;
    user_signs_up(&app).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
        "username": "wrong_username",
        "password": "password1_",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_USERNAME_OR_PASSWORD");
}

#[tokio::test]
async fn logged_in_user_can_access_profile_information() {
    let app = spawn_app().await;
    user_signs_up(&app).await;

    let (access_token, _) = user_logs_in(&app, "testusername", "password1_").await;

    // User can access a route protected by token authentication
    user_has_access_to_protected_route(&app, &access_token).await;
}
