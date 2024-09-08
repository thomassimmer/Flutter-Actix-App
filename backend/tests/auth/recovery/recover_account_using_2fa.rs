use actix_http::Request;
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::ContentType;
use actix_web::{test, Error};
use flutteractixapp::core::structs::responses::GenericResponse;
use flutteractixapp::features::auth::structs::responses::UserLoginResponse;
use totp_rs::{Algorithm, Secret, TOTP};

use crate::auth::otp::{user_generates_otp, user_verifies_otp};
use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

pub async fn user_recovers_account_using_2fa(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    recovery_code: &str,
    code: &str,
) -> (String, String) {
    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-2fa")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
            "code": code,
            "recovery_code": recovery_code,
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserLoginResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_LOGGED_IN_AFTER_ACCOUNT_RECOVERY");

    (response.access_token, response.refresh_token)
}

#[tokio::test]
async fn user_can_recover_account_using_2fa() {
    let app = spawn_app().await;
    let (access_token, _, recovery_codes) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(otp_base32.to_string()).to_bytes().unwrap(),
    )
    .unwrap();
    let code = totp.generate_current().unwrap();

    for recovery_code in recovery_codes {
        let (access_token, _) = user_recovers_account_using_2fa(&app, &recovery_code, &code).await;

        user_has_access_to_protected_route(&app, &access_token).await;
    }
}

#[tokio::test]
async fn user_cannot_recover_account_using_2fa_without_2fa_enabled() {
    let app = spawn_app().await;
    user_signs_up(&app).await;

    // Without this
    // let otp_base32 = user_generates_otp(&app, &access_token).await;
    // user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-2fa")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
            "code": "000000",
            "recovery_code": "wrong_recovery_code",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(403, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "TWO_FACTOR_AUTHENTICATION_NOT_ENABLED");
}

#[tokio::test]
async fn user_cannot_recover_account_using_2fa_with_wrong_code() {
    let app = spawn_app().await;
    let (access_token, _, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-2fa")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
            "code": "000000",
            "recovery_code": "wrong_recovery_code",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_USERNAME_OR_CODE_OR_RECOVERY_CODE");
}

#[tokio::test]
async fn user_cannot_recover_account_using_2fa_with_wrong_username() {
    let app = spawn_app().await;
    let (access_token, _, recovery_codes) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

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
        .uri("/api/auth/recover-using-2fa")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "wrong_username",
            "code": code,
            "recovery_code": recovery_codes[0],
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_USERNAME_OR_CODE_OR_RECOVERY_CODE");
}

#[tokio::test]
async fn user_cannot_recover_account_using_2fa_using_code_twice() {
    let app = spawn_app().await;
    let (access_token, _, recovery_codes) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(otp_base32.to_string()).to_bytes().unwrap(),
    )
    .unwrap();
    let code = totp.generate_current().unwrap();
    let (access_token, _) = user_recovers_account_using_2fa(&app, &recovery_codes[0], &code).await;

    user_has_access_to_protected_route(&app, &access_token).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-2fa")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
            "username": "testusername",
            "recovery_code": recovery_codes[0],
            "code": code
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_USERNAME_OR_CODE_OR_RECOVERY_CODE");
}
