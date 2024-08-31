use actix_http::{header, Request};
use actix_web::{
    body::MessageBody,
    dev::{Service, ServiceResponse},
    http::header::ContentType,
    test, Error,
};
use flutteractixapp::features::auth::structs::responses::UserSignupResponse;

use crate::{helpers::spawn_app, profile::profile::user_has_access_to_protected_route};

pub async fn user_signs_up(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
) -> (String, String) {
    let req = test::TestRequest::post()
        .uri("/api/auth/register")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
        "username": "testusername",
        "password": "password",
        "locale": "en",
        "theme": "dark",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserSignupResponse = serde_json::from_slice(&body).unwrap();

    (response.access_token, response.refresh_token)
}

#[tokio::test]
async fn user_can_signup() {
    let app = spawn_app().await;
    user_signs_up(&app).await;
}

#[tokio::test]
async fn registered_user_can_access_profile_information() {
    let app = spawn_app().await;
    let (access_token, _) = user_signs_up(&app).await;

    // User can access a route protected by token authentication
    user_has_access_to_protected_route(&app, access_token).await;
}

#[tokio::test]
async fn wrong_token_cannot_access_profile_information() {
    let app = spawn_app().await;
    let (access_token, _) = user_signs_up(&app).await;

    // A wrong token would not work
    let wrong_access_token = access_token
        .chars()
        .enumerate()
        .map(|(i, c)| if i == 5 { 'x' } else { c })
        .collect::<String>();

    let req = test::TestRequest::get()
        .uri("/api/users/me")
        .insert_header((
            header::AUTHORIZATION,
            format!("Bearer {}", wrong_access_token),
        ))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());
}

#[tokio::test]
async fn no_token_cannot_access_profile_information() {
    let app = spawn_app().await;

    // No token would not work
    let req = test::TestRequest::get().uri("/api/users/me").to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());
}
