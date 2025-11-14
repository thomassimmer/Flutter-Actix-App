use actix_http::{header, Request};
use actix_web::{
    body::MessageBody,
    dev::{Service, ServiceResponse},
    http::header::ContentType,
    test, Error,
};
use flutteractixapp::{
    core::structs::responses::GenericResponse,
    features::profile::application::dto::{ProfileResponse, SetPasswordRequest},
};
use sqlx::PgPool;

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
    let set_password_request = SetPasswordRequest {
        new_password: new_password.to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/users/set-password")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .insert_header(ContentType::json())
        .set_json(&set_password_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: ProfileResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "PASSWORD_CHANGED");
}

#[sqlx::test]
pub async fn user_can_set_password_after_account_recovery(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (_, _, recovery_codes) = user_signs_up(&app).await;

    let (access_token, _) =
        user_recovers_account_without_2fa_enabled(&app, &recovery_codes[0]).await;

    user_sets_password(&app, &access_token, "new_password1_").await;
    user_logs_in(&app, "testusername", "new_password1_").await;
}

#[sqlx::test]
pub async fn user_cannot_set_password_if_its_not_expired(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, _) = user_signs_up(&app).await;

    let set_password_request = SetPasswordRequest {
        new_password: "new_password1_".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/users/set-password")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .insert_header(ContentType::json())
        .set_json(&set_password_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(403, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "PASSWORD_NOT_EXPIRED");
}
