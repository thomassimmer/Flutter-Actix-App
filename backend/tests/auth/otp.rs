use actix_http::{header, Request};
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::ContentType;
use actix_web::{test, Error};
use reallystick::core::structs::response::GenericResponse;
use reallystick::features::auth::structs::response::{
    DisableOtpResponse, GenerateOtpResponse, UserLoginResponse, UserLoginWhenOtpEnabledResponse,
    VerifyOtpResponse,
};
use totp_rs::{Algorithm, Secret, TOTP};

use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

async fn user_generates_otp(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    access_token: &str,
) -> String {
    let req = test::TestRequest::get()
        .uri("/api/auth/otp/generate")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenerateOtpResponse = serde_json::from_slice(&body).unwrap();

    response.otp_base32.to_owned()
}

async fn user_verifies_otp(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    access_token: &str,
    otp_base32: &str,
) {
    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(otp_base32.to_string()).to_bytes().unwrap(),
    )
    .unwrap();

    let code = totp.generate_current().unwrap();

    let req = test::TestRequest::post()
        .uri("/api/auth/otp/verify")
        .insert_header(ContentType::json())
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .set_json(&serde_json::json!({"code": code}))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: VerifyOtpResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.otp_verified, true);
}

#[tokio::test]
async fn registered_user_can_generate_and_verify_otp() {
    let app = spawn_app().await;

    let (access_token, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;
    user_verifies_otp(&app, &access_token, &otp_base32).await;
}

#[tokio::test]
async fn registered_user_can_validate_otp() {
    let app = spawn_app().await;

    let (access_token, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;
    user_verifies_otp(&app, &access_token, &otp_base32).await;

    // User logs in. Otp is required.
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
    let response: UserLoginWhenOtpEnabledResponse = serde_json::from_slice(&body).unwrap();

    // A TOTP is necessary to log in.
    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(otp_base32.to_string()).to_bytes().unwrap(),
    )
    .unwrap();

    let code = totp.generate_current().unwrap();

    let req = test::TestRequest::post()
        .uri("/api/auth/otp/validate")
        .insert_header(ContentType::json())
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .set_json(&serde_json::json!({"code": code, "user_id": response.user_id}))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserLoginResponse = serde_json::from_slice(&body).unwrap();

    user_has_access_to_protected_route(&app, response.access_token).await;
}

#[tokio::test]
async fn registered_user_can_disable_otp() {
    let app = spawn_app().await;

    let (access_token, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;
    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::get()
        .uri("/api/auth/otp/disable")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: DisableOtpResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.otp_enabled, false);
}

#[tokio::test]
async fn wrong_token_user_can_generate_otp() {
    let app = spawn_app().await;

    let req = test::TestRequest::get()
        .uri("/api/auth/otp/generate")
        .insert_header((header::AUTHORIZATION, "Bearer invalid token"))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.status, "fail");
    assert_eq!(response.message, "Token decoding error: InvalidToken");
}
