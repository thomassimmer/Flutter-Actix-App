use reqwest::Client;
use serde_json::Value;
use totp_rs::{Algorithm, Secret, TOTP};

use crate::auth::signup::{user_accesses_protected_route, user_signs_up};
use crate::helpers::{spawn_app, TestApp};

async fn user_generates_otp(app: &TestApp, client: Client, access_token: &str) -> String {
    let response = client
        .get(&format!("{}/api/auth/otp/generate", &app.address))
        .bearer_auth(access_token.to_owned())
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(200, response.status().as_u16());

    let body = response
        .json::<Value>()
        .await
        .expect("Failed to parse JSON");

    assert_eq!(body.get("status").and_then(Value::as_str), Some("success"));
    assert!(body.get("otp_base32").is_some());
    assert!(body.get("otp_auth_url").is_some());

    let otp_base32 = body
        .get("otp_base32")
        .and_then(Value::as_str)
        .expect("Failed to get otp_base32");

    otp_base32.to_owned()
}

async fn user_verifies_otp(app: &TestApp, client: Client, access_token: &str, otp_base32: &str) {
    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(otp_base32.to_string()).to_bytes().unwrap(),
    )
    .unwrap();

    let code = totp.generate_current().unwrap();

    let response = client
        .post(&format!("{}/api/auth/otp/verify", &app.address))
        .bearer_auth(access_token.to_owned())
        .json(&serde_json::json!({"token": code}))
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(200, response.status().as_u16());

    let body = response
        .json::<Value>()
        .await
        .expect("Failed to parse JSON");

    assert_eq!(body.get("status").and_then(Value::as_str), Some("success"));
    assert_eq!(body.get("otp_verified").unwrap(), true);
}

#[tokio::test]
async fn registered_user_can_generate_and_verify_otp() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    let (access_token, _) = user_signs_up(&app, client.clone()).await;
    let otp_base32 = user_generates_otp(&app, client.clone(), &access_token).await;
    user_verifies_otp(&app, client.clone(), &access_token, &otp_base32).await;
}

#[tokio::test]
async fn registered_user_can_validate_otp() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    let (access_token, _) = user_signs_up(&app, client.clone()).await;
    let otp_base32 = user_generates_otp(&app, client.clone(), &access_token).await;
    user_verifies_otp(&app, client.clone(), &access_token, &otp_base32).await;

    // User logs in. Otp is required.
    let response = client
        .post(&format!("{}/api/auth/login", &app.address))
        .json(&serde_json::json!({
            "username": "testusername",
            "password": "password",
        }))
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(200, response.status().as_u16());

    let body = response
        .json::<Value>()
        .await
        .expect("Failed to parse JSON");

    assert_eq!(body.get("status").and_then(Value::as_str), Some("success"));
    assert!(body.get("user_id").is_some());

    let user_id = body
        .get("user_id")
        .and_then(Value::as_str)
        .expect("Failed to get user_id");

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

    let response = client
        .post(&format!("{}/api/auth/otp/validate", &app.address))
        .json(&serde_json::json!({
            "user_id": user_id,
            "token": code,
        }))
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(200, response.status().as_u16());

    let body = response
        .json::<Value>()
        .await
        .expect("Failed to parse JSON");

    assert_eq!(body.get("status").and_then(Value::as_str), Some("success"));
    assert!(body.get("access_token").is_some());
    assert!(body.get("refresh_token").is_some());
    assert!(body.get("expires_in").is_some());

    let access_token = body
        .get("access_token")
        .and_then(Value::as_str)
        .expect("Failed to get access_token")
        .to_string();

    user_accesses_protected_route(&app, client.clone(), access_token).await;
}

#[tokio::test]
async fn registered_user_can_disable_otp() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    let (access_token, _) = user_signs_up(&app, client.clone()).await;
    let otp_base32 = user_generates_otp(&app, client.clone(), &access_token).await;
    user_verifies_otp(&app, client.clone(), &access_token, &otp_base32).await;

    let response = client
        .get(&format!("{}/api/auth/otp/disable", &app.address))
        .bearer_auth(access_token.clone())
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(200, response.status().as_u16());

    let body = response
        .json::<Value>()
        .await
        .expect("Failed to parse JSON");

    assert_eq!(body.get("status").and_then(Value::as_str), Some("success"));
    assert_eq!(body.get("otp_enabled").unwrap(), false);
}

#[tokio::test]
async fn wrong_token_user_can_generate_otp() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();

    let response = client
        .get(&format!("{}/api/auth/otp/generate", &app.address))
        .bearer_auth("invalid token")
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(401, response.status().as_u16());

    let body = response
        .json::<Value>()
        .await
        .expect("Failed to parse JSON");

    assert_eq!(body.get("status").and_then(Value::as_str), Some("fail"));
    assert_eq!(
        body.get("message").and_then(Value::as_str),
        Some("Token decoding error: InvalidToken")
    );
}
