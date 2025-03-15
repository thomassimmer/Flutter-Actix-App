use actix_http::{header, Request};
use actix_web::{
    body::MessageBody,
    dev::{Service, ServiceResponse},
    http::header::ContentType,
    test, Error,
};
use flutteractixapp::{core::structs::responses::GenericResponse, features::profile::structs::responses::UserResponse};

use crate::{
    auth::{
        login::user_logs_in,
        recovery::recover_account_without_2fa_enabled::user_recovers_account_without_2fa_enabled,
        signup::user_signs_up,
    },
    helpers::spawn_app,
};

pub async fn user_sets_password(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    access_token: &str,
    new_password: &str,
) {
    let req = test::TestRequest::post()
        .uri("/api/users/set-password")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "new_password": new_password,
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "PASSWORD_CHANGED");
}

#[tokio::test]
pub async fn user_can_set_password_after_account_recovery() {
    let app = spawn_app().await;
    let (_, _, recovery_codes) = user_signs_up(&app).await;

    let (access_token, _) =
        user_recovers_account_without_2fa_enabled(&app, &recovery_codes[0]).await;

    user_sets_password(&app, &access_token, "new_password1_").await;
    user_logs_in(&app, "testusername", "new_password1_").await;
}

#[tokio::test]
pub async fn user_cannot_set_password_if_its_not_expired() {
    let app = spawn_app().await;
    let (access_token, _, _) = user_signs_up(&app).await;

    let req = test::TestRequest::post()
        .uri("/api/users/set-password")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "new_password": "new_password1_",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(403, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "PASSWORD_NOT_EXPIRED");
}
