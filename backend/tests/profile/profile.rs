use actix_http::{header, Request};
use actix_web::{
    body::MessageBody,
    dev::{Service, ServiceResponse},
    http::header::ContentType,
    test, Error,
};
use flutteractixapp::features::profile::structs::responses::{IsOtpEnabledResponse, UserResponse};

use crate::{
    auth::{
        otp::{user_generates_otp, user_verifies_otp},
        signup::user_signs_up,
    },
    helpers::spawn_app,
};

pub async fn user_has_access_to_protected_route(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    access_token: &str,
) {
    let req = test::TestRequest::get()
        .uri("/api/users/me")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "PROFILE_FETCHED");
    assert_eq!(response.user.username, "testusername");
    assert_eq!(response.user.locale, "en");
}

#[tokio::test]
pub async fn user_can_update_profile() {
    let app = spawn_app().await;
    let (access_token, _, _) = user_signs_up(&app).await;

    user_has_access_to_protected_route(&app, &access_token).await;

    let req = test::TestRequest::post()
        .uri("/api/users/me")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
            "locale": "fr",
            "theme": "light",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "PROFILE_UPDATED");
    assert_eq!(response.user.username, "testusername");
    assert_eq!(response.user.locale, "fr");
    assert_eq!(response.user.theme, "light");
}

#[tokio::test]
pub async fn is_otp_enabled_for_user_that_activated_it() {
    let app = spawn_app().await;
    let (access_token, _, _) = user_signs_up(&app).await;

    let req = test::TestRequest::post()
        .uri("/api/users/is-otp-enabled")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: IsOtpEnabledResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "OTP_STATUS");
    assert_eq!(response.otp_enabled, false);

    // User only generates OTP
    user_generates_otp(&app, &access_token).await;

    let req = test::TestRequest::post()
        .uri("/api/users/is-otp-enabled")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: IsOtpEnabledResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "OTP_STATUS");
    assert_eq!(response.otp_enabled, false);

    // User generates and validates OTP
    let otp_base32 = user_generates_otp(&app, &access_token).await;
    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::post()
        .uri("/api/users/is-otp-enabled")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: IsOtpEnabledResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "OTP_STATUS");
    assert_eq!(response.otp_enabled, true);
}
