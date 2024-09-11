use actix_http::{header, Request};
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::ContentType;
use actix_web::{test, Error};
use flutteractixapp::core::structs::responses::GenericResponse;
use flutteractixapp::features::auth::structs::responses::{
    DisableOtpResponse, GenerateOtpResponse, UserLoginResponse, UserLoginWhenOtpEnabledResponse,
    VerifyOtpResponse,
};
use totp_rs::{Algorithm, Secret, TOTP};
use uuid::Uuid;

use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

pub async fn user_generates_otp(
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

    assert_eq!(response.code, "OTP_GENERATED");

    response.otp_base32.to_owned()
}

pub async fn user_verifies_otp(
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

    assert_eq!(response.code, "OTP_VERIFIED");
    assert_eq!(response.otp_verified, true);
}

#[tokio::test]
async fn registered_user_can_generate_and_verify_otp() {
    let app = spawn_app().await;

    let (access_token, _, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;
    user_verifies_otp(&app, &access_token, &otp_base32).await;
}

#[tokio::test]
async fn registered_user_can_validate_otp() {
    let app = spawn_app().await;

    let (access_token, _, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;
    user_verifies_otp(&app, &access_token, &otp_base32).await;

    // User logs in. Otp is required.
    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
        "username": "testusername",
        "password": "password1_",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserLoginWhenOtpEnabledResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_LOGS_IN_WITH_OTP_ENABLED");

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

    assert_eq!(response.code, "USER_LOGGED_IN_AFTER_OTP_VALIDATION");

    user_has_access_to_protected_route(&app, &response.access_token).await;
}

#[tokio::test]
async fn registered_user_can_disable_otp() {
    let app = spawn_app().await;

    let (access_token, _, _) = user_signs_up(&app).await;
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

    assert_eq!(response.code, "OTP_DISABLED");
    assert_eq!(response.two_fa_enabled, false);
}

#[tokio::test]
async fn user_cannot_generate_otp_with_wrong_token() {
    let app = spawn_app().await;

    let req = test::TestRequest::get()
        .uri("/api/auth/otp/generate")
        .insert_header((header::AUTHORIZATION, "Bearer invalid token"))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_ACCESS_TOKEN");
}

#[tokio::test]
async fn user_cannot_validate_otp_for_a_wrong_user() {
    let app = spawn_app().await;
    let (access_token, _, _) = user_signs_up(&app).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/otp/validate")
        .insert_header(ContentType::json())
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .set_json(&serde_json::json!({"code": "000000", "user_id": Uuid::new_v4()}))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(404, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_NOT_FOUND");
}
