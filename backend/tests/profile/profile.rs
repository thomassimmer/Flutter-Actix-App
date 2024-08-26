use actix_http::{header, Request};
use actix_web::{
    body::MessageBody,
    dev::{Service, ServiceResponse},
    http::header::ContentType,
    test, Error,
};
use reallystick::profile::structs::response::UserResponse;

use crate::{auth::signup::user_signs_up, helpers::spawn_app};

pub async fn user_accesses_protected_route(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    access_token: String,
) {
    let req = test::TestRequest::get()
        .uri("/api/users/me")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.user.username, "testusername");
    assert_eq!(response.user.locale, "en");
}

#[tokio::test]
pub async fn user_update_its_profile() {
    let app = spawn_app().await;
    let (access_token, _) = user_signs_up(&app).await;

    user_accesses_protected_route(&app, access_token.clone()).await;

    let req = test::TestRequest::post()
        .uri("/api/users/me")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
            "locale": "fr",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.user.username, "testusername");
    assert_eq!(response.user.locale, "fr");
}
