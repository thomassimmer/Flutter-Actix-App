use actix_http::{header, Request};
use actix_web::{
    body::MessageBody,
    dev::{Service, ServiceResponse},
    http::header::ContentType,
    test, Error,
};
use flutteractixapp::{
    core::structs::responses::GenericResponse,
    features::auth::application::dto::{SignupRequest, SignupResponse},
};
use sqlx::PgPool;

use crate::{helpers::spawn_app, profile::profile::user_has_access_to_protected_route};

pub async fn user_signs_up(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
) -> (String, String, Vec<String>) {
    let signup_request = SignupRequest {
        username: "testusername".to_string(),
        password: "password1_".to_string(),
        locale: "en".to_string(),
        theme: "dark".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/signup")
        .insert_header(ContentType::json())
        .set_json(&signup_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(201, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: SignupResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_SIGNED_UP");

    (
        response.access_token,
        response.refresh_token,
        response.recovery_codes,
    )
}

#[sqlx::test]
async fn user_can_signup(pool: PgPool) {
    let app = spawn_app(pool).await;
    user_signs_up(&app).await;
}

#[sqlx::test]
async fn registered_user_can_access_profile_information(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, _) = user_signs_up(&app).await;

    // User can access a route protected by token authentication
    user_has_access_to_protected_route(&app, &access_token).await;
}

#[sqlx::test]
async fn user_with_invalid_token_cannot_access_profile_information(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (access_token, _, _) = user_signs_up(&app).await;

    // A wrong token would not work
    let wrong_access_token = access_token
        .chars()
        .enumerate()
        .map(|(i, c)| if i == 5 { 'x' } else { c })
        .collect::<String>();

    let req = test::TestRequest::get()
        .uri("/api/users/me")
        .insert_header((
            header::AUTHORIZATION,
            format!("Bearer {}", wrong_access_token),
        ))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "INVALID_ACCESS_TOKEN");
}

#[sqlx::test]
async fn unauthenticated_user_cannot_access_profile_information(pool: PgPool) {
    let app = spawn_app(pool).await;
    let req = test::TestRequest::get().uri("/api/users/me").to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());
}

#[sqlx::test]
async fn user_cannot_signup_with_existing_username(pool: PgPool) {
    let app = spawn_app(pool).await;
    user_signs_up(&app).await;

    let signup_request = SignupRequest {
        username: "testusername".to_string(),
        password: "password1_".to_string(),
        locale: "en".to_string(),
        theme: "dark".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/signup")
        .insert_header(ContentType::json())
        .set_json(&signup_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(409, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USER_ALREADY_EXISTS");
}

#[sqlx::test]
async fn user_cannot_signup_with_short_password(pool: PgPool) {
    let app = spawn_app(pool).await;

    let signup_request = SignupRequest {
        username: "testusername".to_string(),
        password: "passwor".to_string(),
        locale: "en".to_string(),
        theme: "dark".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/signup")
        .insert_header(ContentType::json())
        .set_json(&signup_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "PASSWORD_TOO_SHORT");
}

#[sqlx::test]
async fn user_cannot_signup_with_short_username(pool: PgPool) {
    let app = spawn_app(pool).await;

    let signup_request = SignupRequest {
        username: "te".to_string(),
        password: "password1_".to_string(),
        locale: "en".to_string(),
        theme: "dark".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/signup")
        .insert_header(ContentType::json())
        .set_json(&signup_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USERNAME_WRONG_SIZE");
}

#[sqlx::test]
async fn user_cannot_signup_with_long_username(pool: PgPool) {
    let app = spawn_app(pool).await;

    let signup_request = SignupRequest {
        username: "testusernametestusernametestusername".to_string(),
        password: "password1_".to_string(),
        locale: "en".to_string(),
        theme: "dark".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/signup")
        .insert_header(ContentType::json())
        .set_json(&signup_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USERNAME_WRONG_SIZE");
}

#[sqlx::test]
async fn user_cannot_signup_with_username_not_respecting_rules(pool: PgPool) {
    let app = spawn_app(pool).await;

    let signup_request = SignupRequest {
        username: "__x__".to_string(),
        password: "password1_".to_string(),
        locale: "en".to_string(),
        theme: "dark".to_string(),
    };
    let req = test::TestRequest::post()
        .uri("/api/auth/signup")
        .insert_header(ContentType::json())
        .set_json(&signup_request)
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: GenericResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "USERNAME_NOT_RESPECTING_RULES");
}
