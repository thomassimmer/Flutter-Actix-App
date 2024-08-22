use serde_json::Value;

use crate::helpers::spawn_app;

#[tokio::test]
async fn health_check() {
    let app = spawn_app().await;
    let client = reqwest::Client::new();

    let response = client
        .get(&format!("{}/health_check", &app.address))
        .send()
        .await
        .expect("Failed to execute request.");

    assert_eq!(200, response.status().as_u16());

    // Parse the response body as JSON
    let body = response
        .json::<Value>()
        .await
        .expect("Failed to parse JSON");

    // Check the "message" key in the JSON response
    assert_eq!(
        body.get("message").and_then(Value::as_str),
        Some("Server is running fine")
    );
}