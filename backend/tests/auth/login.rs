use reqwest::Client;
use serde_json::Value;

use crate::auth::signup::user_signs_up;
use crate::helpers::{spawn_app, TestApp};

pub async fn user_logs_in(app: &TestApp, client: Client) -> (String, String) {
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
    assert!(body.get("access_token").is_some());
    assert!(body.get("refresh_token").is_some());
    assert!(body.get("expires_in").is_some());

    let access_token = body
        .get("access_token")
        .and_then(Value::as_str)
        .expect("Failed to get access_token");

    let refresh_token = body
        .get("refresh_token")
        .and_then(Value::as_str)
        .expect("Failed to get refresh_token");

    (access_token.to_string(), refresh_token.to_string())
}

#[tokio::test]
async fn user_can_login() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    user_signs_up(&app, client.clone()).await;
    user_logs_in(&app, client.clone()).await;
}

#[tokio::test]
async fn logged_in_user_can_access_profile_information() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    user_signs_up(&app, client.clone()).await;

    let (access_token, _) = user_logs_in(&app, client.clone()).await;

    // User can access a route protected by token authentication
    let response = client
        .get(&format!("{}/api/users/me", &app.address))
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
    assert!(body.get("user").is_some());
}
