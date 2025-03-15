use reqwest::Client;
use serde_json::Value;

use crate::helpers::{spawn_app, TestApp};

pub async fn user_signs_up(app: &TestApp, client: Client) -> String {
    let response = client
        .post(&format!("{}/auth/register", &app.address))
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
    assert!(body.get("recovery_codes").is_some());
    assert!(body.get("access_token").is_some());
    assert!(body.get("refresh_token").is_some());
    assert!(body.get("expires_in").is_some());

    let access_token = body
        .get("access_token")
        .and_then(Value::as_str)
        .expect("Failed to get access_token");

    access_token.to_string()
}

#[tokio::test]
async fn user_can_signup() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    user_signs_up(&app, client.clone()).await;
}

#[tokio::test]
async fn registered_user_can_access_profile_information() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    let access_token = user_signs_up(&app, client.clone()).await;

    // User can access a route protected by token authentication
    let response = client
        .get(&format!("{}/users/me", &app.address))
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

#[tokio::test]
async fn wrong_token_cannot_access_profile_information() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();
    let access_token = user_signs_up(&app, client.clone()).await;

    // A wrong token would not work
    let wrong_access_token = access_token
        .chars()
        .enumerate()
        .map(|(i, c)| if i == 5 { 'x' } else { c })
        .collect::<String>();

    let response = client
        .get(&format!("{}/users/me", &app.address))
        .bearer_auth(wrong_access_token)
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(401, response.status().as_u16());
}

#[tokio::test]
async fn no_token_cannot_access_profile_information() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();

    // No token would not work
    let response = client
        .get(&format!("{}/users/me", &app.address))
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(401, response.status().as_u16());
}
