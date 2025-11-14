use actix_http::Request;
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::ContentType;
use actix_web::{test, Error};
use flutteractixapp::core::structs::responses::GenericResponse;
use flutteractixapp::features::auth::application::dto::{LoginResponse, RecoverAccountUsingPasswordRequest};
use flutteractixapp::features::profile::application::dto::{IsOtpEnabledRequest, IsOtpEnabledResponse};
use sqlx::PgPool;

use crate::auth::otp::{user_generates_otp, user_verifies_otp};
use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;
use crate::profile::profile::user_has_access_to_protected_route;

pub async fn user_recovers_account_using_password(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    recovery_code: &str,
    password: &str,
) -> (String, String) {
    let recovery_request = RecoverAccountUsingPasswordRequest {
        username: "testusername".to_string(),
        password: password.to_string(),
        recovery_code: recovery_code.to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-password")
        .insert_header(ContentType::json())
        .set_json(&recovery_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: LoginResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_LOGGED_IN_AFTER_ACCOUNT_RECOVERY");

    (response.access_token, response.refresh_token)
}

#[sqlx::test]
async fn user_can_recover_account_using_password(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (mut access_token, _, recovery_codes) = user_signs_up(&app).await;

    for recovery_code in recovery_codes {
        let otp_base32 = user_generates_otp(&app, &access_token).await;

        user_verifies_otp(&app, &access_token, &otp_base32).await;

        access_token = user_recovers_account_using_password(&app, &recovery_code, "password1_")
            .await
            .0;

        user_has_access_to_protected_route(&app, &access_token).await;
    }

    // 2FA should be disabled
    let req = test::TestRequest::post()
        .uri("/api/users/is-otp-enabled")
        .insert_header(ContentType::json())
        .set_json(&IsOtpEnabledRequest {
            username: "testusername".to_string(),
        })
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: IsOtpEnabledResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.otp_enabled, false);
}

#[sqlx::test]
async fn user_cannot_recover_using_password_without_2fa(pool: PgPool) {
    let app = spawn_app(pool).await;
    user_signs_up(&app).await;

    // Without this
    // let otp_base32 = user_generates_otp(&app, &access_token).await;
    // user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-password")
        .insert_header(ContentType::json())
        .set_json(&RecoverAccountUsingPasswordRequest {
            username: "testusername".to_string(),
            recovery_code: "wrong_recovery_code".to_string(),
            password: "password1_".to_string(),
        })
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(403, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "TWO_FACTOR_AUTHENTICATION_NOT_ENABLED");
}

#[sqlx::test]
async fn user_cannot_recover_account_using_password_with_wrong_code(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, _) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-password")
        .insert_header(ContentType::json())
        .set_json(&RecoverAccountUsingPasswordRequest {
            username: "testusername".to_string(),
            recovery_code: "wrong_recovery_code".to_string(),
            password: "password1_".to_string(),
        })
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(
        response.code,
        "INVALID_USERNAME_OR_PASSWORD_OR_RECOVERY_CODE"
    );
}

#[sqlx::test]
async fn user_cannot_recover_account_using_password_with_wrong_username(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, recovery_codes) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-password")
        .insert_header(ContentType::json())
        .set_json(&RecoverAccountUsingPasswordRequest {
            username: "wrong_username".to_string(),
            recovery_code: recovery_codes[0].clone(),
            password: "password1_".to_string(),
        })
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(
        response.code,
        "INVALID_USERNAME_OR_PASSWORD_OR_RECOVERY_CODE"
    );
}

#[sqlx::test]
async fn user_cannot_recover_account_using_password_with_wrong_password(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, recovery_codes) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-password")
        .insert_header(ContentType::json())
        .set_json(&RecoverAccountUsingPasswordRequest {
            username: "testusername".to_string(),
            recovery_code: recovery_codes[0].clone(),
            password: "wrong_password".to_string(),
        })
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(
        response.code,
        "INVALID_USERNAME_OR_PASSWORD_OR_RECOVERY_CODE"
    );
}

#[sqlx::test]
async fn user_cannot_recover_account_using_password_using_code_twice(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, recovery_codes) = user_signs_up(&app).await;
    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let (access_token, _) =
        user_recovers_account_using_password(&app, &recovery_codes[0], "password1_").await;

    user_has_access_to_protected_route(&app, &access_token).await;

    let otp_base32 = user_generates_otp(&app, &access_token).await;

    user_verifies_otp(&app, &access_token, &otp_base32).await;

    let req = test::TestRequest::post()
        .uri("/api/auth/recover-using-password")
        .insert_header(ContentType::json())
        .set_json(&RecoverAccountUsingPasswordRequest {
            username: "testusername".to_string(),
            recovery_code: recovery_codes[0].clone(),
            password: "password1_".to_string(),
        })
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(
        response.code,
        "INVALID_USERNAME_OR_PASSWORD_OR_RECOVERY_CODE"
    );
}
