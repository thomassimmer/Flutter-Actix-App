use actix_http::Request;
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::ContentType;
use actix_web::{test, Error};
use flutteractixapp::features::auth::structs::responses::UserLoginResponse;

use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

pub async fn user_logs_in(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
) -> (String, String) {
    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
        "username": "testusername",
        "password": "password",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserLoginResponse = serde_json::from_slice(&body).unwrap();

    (response.access_token, response.refresh_token)
}

#[tokio::test]
async fn user_can_login() {
    let app = spawn_app().await;
    user_signs_up(&app).await;
    user_logs_in(&app).await;
}

#[tokio::test]
async fn logged_in_user_can_access_profile_information() {
    let app = spawn_app().await;
    user_signs_up(&app).await;

    let (access_token, _) = user_logs_in(&app).await;

    // User can access a route protected by token authentication
    user_has_access_to_protected_route(&app, access_token).await;
}
