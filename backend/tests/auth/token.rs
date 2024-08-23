use reqwest::Client;
use serde_json::Value;

use crate::auth::login::user_logs_in;
use crate::auth::signup::user_signs_up;
use crate::helpers::{spawn_app, TestApp};

pub async fn user_refreshes_token(app: &TestApp, client: Client, refresh_token: String) -> String {
    let response = client
        .post(&format!("{}/api/auth/refresh-token", &app.address))
        .json(&serde_json::json!({
            "refresh_token": refresh_token,
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
    assert!(body.get("expires_in").is_some());

    let access_token = body
        .get("access_token")
        .and_then(Value::as_str)
        .expect("Failed to get access_token");

    access_token.to_string()
}

#[tokio::test]
async fn user_can_refresh_token() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    user_signs_up(&app, client.clone()).await;
    let (_, refresh_token) = user_logs_in(&app, client.clone()).await;
    user_refreshes_token(&app, client.clone(), refresh_token).await;
}
