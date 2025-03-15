Available at: https://medium.com/@thomas.simmer/building-a-cross-platform-app-with-flutter-and-rust-writing-integration-tests-b018d472c19a

# Building a Cross-Platform App with Flutter and Rust: Writing Integration Tests

## Introduction

In this article, I’ll walk you through how I wrote integration tests for a cross-platform app built using Flutter for the frontend and Actix for the backend. The app has several key features, including:

1. A login/signup page using a username and password (without email, for privacy).
2. A recovery code page for new users.
3. A 2FA setup page using OTP with an external app like Google Authenticator.
4. A main app view with four tabs.
5. A profile tab where users can change settings like language, theme, 2FA and logout.
6. An account recovery page for users who lose access to 2FA or their password.

For more context, feel free to check out [the first article](https://medium.com/@thomas.simmer/building-a-cross-platform-app-with-flutter-and-rust-a-beginners-journey-92cbb893c2f9) of this series.

My API uses these crates:

- **actix-web** for managing routes, running the server, and writing tests.
- **sqlx** for safe asynchronous database queries.
- **jsonwebtoken** to handle token creation and decoding.
- **argon2** for secure password hashing.
- **secrecy** to safeguard sensitive data.
- **totp-rs** to generate and validate one-time passwords (OTPs).

## Goals of the Integration Tests

I needed to ensure the API handled these user actions seamlessly:

- Sign up using a username and password.
- Receive recovery codes upon registration, as we don’t use email.
- Recover access using recovery codes in case of password or 2FA loss.
- Enable 2FA after registration by scanning a QR code and verifying it with an OTP.
- Verify OTP on every login if 2FA is enabled.
- Manage profile settings (language, theme, and 2FA) from a profile page.
- Maintain secure sessions with an access token (expires in 15 minutes) and a refresh token (expires in 7 days).

The integration tests needed to ensure not only that these actions were possible but also that improper usage was prevented.

## Challenges in Writing Integration Tests

1. Handling Concurrency

A common issue with API integration tests is test concurrency. When running tests with **cargo test**, Rust runs tests in parallel, leading to potential conflicts if multiple tests query the same database simultaneously. These conflicts can cause random test failures.

One solution is to use database transactions for each test and roll them back afterward. While this works well in simple cases, it becomes challenging when your test involves state variables, such as a shared **database connection pool**.

Another approach is to use a separate database instance for each test. Ideally, this would be an in-memory database to avoid manual cleanup. Unfortunately, PostgreSQL doesn’t support in-memory databases, so this method is only viable with SQLite.

Inspired by [zero2prod](https://www.lpalmieri.com/posts/2020-08-31-zero-to-production-3-5-html-forms-databases-integration-tests/#3-2-choosing-a-database-crate), I opted to create a new PostgreSQL database for each test, using a unique UUID as the database name to avoid conflicts. Each test creates its own database, sets up a connection pool, runs the necessary migrations, and proceeds to execute.

2. Controlling Time in Tests

Another challenge arises when controlling time-sensitive logic, such as expiring tokens, in your tests. Rust’s **chrono::Utc::now** doesn’t provide an easy way to “freeze” time during tests, like **Python’s freezegun**.

Fortunately, there’s a pull request in the works on [chrono's GitHub](https://github.com/chronotope/chrono/pull/1244/files) that introduces the OVERRIDE_NOW variable, allowing you to override the current time on a per-thread basis. Here’s the relevant part of the PR:

```rust
// Value to use for `Utc::now()` and `Local::now()`, when set with `Local::override_now`.
#[cfg(all(feature = "clock", feature = "test-override"))]
thread_local!(
    pub(super) static OVERRIDE_NOW: RefCell<Option<DateTime<FixedOffset>>> = RefCell::new(None)
);
```

With **OVERRIDE_NOW**, you can mock the current time in your tests without affecting other tests. By creating a custom now function, you can either use the overridden time (if set) or fall back to **Utc::now()**:

```rust
use chrono::{DateTime, FixedOffset, Utc};
use std::cell::RefCell;

// To override the time. Needed for tests.
pub fn override_now(datetime: Option<DateTime<FixedOffset>>) {
    OVERRIDE_NOW.with(|o| *o.borrow_mut() = datetime)
}

// Function to use instead of Utc::now straight.
pub fn now() -> DateTime<Utc> {
    if let Some(t) = OVERRIDE_NOW.with(|o| *o.borrow()) {
        return t.into();
    }

    Utc::now()
}
```

Using this method, you can control time during tests. However, this approach doesn’t work with a server running in a separate thread, such as when using the reqwest crate for HTTP requests like zero2prod did. Instead, I rely on Actix’s test utilities, which run the app in the same thread as the test, making time control easier.

Here’s a basic example using Actix’s utilities:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, web, App};

    #[actix_web::test]
    async fn test_index_get() {
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(AppState { count: 4 }))
                .service(index),
        )
        .await;
        let req = test::TestRequest::get().uri("/").to_request();
        let resp: AppState = test::call_and_read_body_json(&app, req).await;

        assert_eq!(resp.count, 4);
    }
}
```

The good news is that I didn’t need to rewrite my entire app with all the routes and web::Data variables for each test. Instead, I created a function in src/startup.rs that sets everything up:

```rust
pub fn create_app(
    configuration: &Settings,
) -> App<
    impl ServiceFactory<
        ServiceRequest,
        Config = (),
        Response = ServiceResponse<impl MessageBody>,
        Error = Error,
        InitError = (),
    >,
> {
    let connection_pool = get_connection_pool(&configuration.database);
    let secret = &configuration.application.secret;

    App::new()
        .service(
            web::scope("/api")
                .service(health_check)
                ... // The rest is not important here
```

Here’s a basic test, like signing up a user:

```rust
pub async fn user_signs_up(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
) -> (String, String) {
    let req = test::TestRequest::post()
        .uri("/api/auth/signup")
        .insert_header(ContentType::json())
        .set_json(&serde_json::json!({
        "username": "testusername",
        "password": "password1_",
        "locale": "en",
        "theme": "dark",
        }))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: UserSignupResponse = serde_json::from_slice(&body).unwrap();

    (response.access_token, response.refresh_token)
}

#[tokio::test]
async fn user_can_signup() {
    let app = spawn_app().await;
    user_signs_up(&app).await;
}
```

Now, if I want to test the expiration of an access token, I can control time using the previously mentioned override_now method:

```rust
#[tokio::test]
async fn access_token_becomes_expired_after_15_minutes() {
    let app = spawn_app().await;

    let (access_token, _) = user_signs_up(&app).await;

    user_has_access_to_protected_route(&app, access_token.clone()).await;

    override_now(Some(
        (Utc::now() + Duration::new(14 * 60, 1)).fixed_offset(),
    ));

    // After 14 minutes, user can still access protected route
    user_has_access_to_protected_route(&app, access_token.clone()).await;

    override_now(Some(
        (Utc::now() + Duration::new(15 * 60, 1)).fixed_offset(),
    ));

    // After 15 minutes, user cannot access protected route anymore
    let req = test::TestRequest::default()
        .uri("/api/users/me")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(401, response.status().as_u16());

    let body = test::read_body(response).await;
    let profile_response: GenericResponse = serde_json::from_slice(&body).unwrap();
    let message = profile_response.message;

    assert_eq!(message, "Token expired");
}
```

And that’s it! I hope you found this useful. Feel free to leave a comment if you have any questions or thoughts.

See you in the next article,
Thomas

[![Watch the video](/docs/screenshots/1.png)](https://youtu.be/ZCqYWs-lrRM)
