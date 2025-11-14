use actix_http::{header, Request};
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::ContentType;
use actix_web::{test, Error};
use flutteractixapp::core::structs::responses::GenericResponse;
use flutteractixapp::features::auth::application::dto::{DisableOtpResponse, GenerateOtpResponse, LoginRequest, LoginResponse, LoginWhenOtpEnabledResponse, ValidateOtpRequest, VerifyOtpRequest, VerifyOtpResponse};
use sqlx::PgPool;
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

    let verify_request = VerifyOtpRequest {
        code: code,
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/otp/verify")
        .insert_header(ContentType::json())
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .set_json(&verify_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: VerifyOtpResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "OTP_VERIFIED");
    assert_eq!(response.otp_verified, true);
}

#[sqlx::test]
async fn registered_user_can_generate_and_verify_otp(pool: PgPool) {
    let app = spawn_app(pool).await;

    let (access_token, _, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;
    user_verifies_otp(&app, &access_token, &otp_base32).await;
}

#[sqlx::test]
async fn registered_user_can_validate_otp(pool: PgPool) {
    let app = spawn_app(pool).await;

    let (access_token, _, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;
    user_verifies_otp(&app, &access_token, &otp_base32).await;

    // User logs in. Otp is required.
    let login_request = LoginRequest {
        username: "testusername".to_string(),
        password: "password1_".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/login")
        .insert_header(ContentType::json())
        .set_json(&login_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: LoginWhenOtpEnabledResponse = serde_json::from_slice(&body).unwrap();

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
    let user_id: Uuid = response.user_id.parse().unwrap();

    let validate_request = ValidateOtpRequest {
        code: code,
        user_id: user_id,
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/otp/validate")
        .insert_header(ContentType::json())
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .set_json(&validate_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: LoginResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_LOGGED_IN_AFTER_OTP_VALIDATION");

    user_has_access_to_protected_route(&app, &response.access_token).await;
}

#[sqlx::test]
async fn registered_user_can_disable_otp(pool: PgPool) {
    let app = spawn_app(pool).await;

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

#[sqlx::test]
async fn user_cannot_generate_otp_with_wrong_token(pool: PgPool) {
    let app = spawn_app(pool).await;

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

#[sqlx::test]
async fn user_cannot_validate_otp_for_a_wrong_user(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, _) = user_signs_up(&app).await;

    let validate_request = ValidateOtpRequest {
        code: "000000".to_string(),
        user_id: Uuid::new_v4(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/otp/validate")
        .insert_header(ContentType::json())
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .set_json(&validate_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(404, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_NOT_FOUND");
}
