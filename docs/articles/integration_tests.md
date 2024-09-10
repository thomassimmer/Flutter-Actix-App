# Building a Flutter / Rust app: Integration tests

## Context

This article explains how I wrote integration tests for my Flutter/Rust app with:

- a first page where you can login / signup using a username and a password (no email because my user shouldn't be personally identifiable)
- a second page where freshly registered users can see their recovery codes
- a third page where freshly registered users can enable 2-factor authentication (2FA) with one-time passwords (OTP) using an external app like Google's Authenticator
- a fourth page that is a typical app view with four tabs using a common base screen with a logout button
- a fifth page for the profile tab where people can change their languages, theme and enable/disable 2FA

Don't hesitate to read the first article of this serie to get more context, [](here).

My API uses these crates:

- **actix**, the web framework, to write my routes, run my server, write my tests, etc...
- **sqlx**, to connect and safely query my database asynchronously
- **jsonwebtoken** to generate and decode tokens
- **argon2** for password hashing
- **secrecy** for ensuring my app's secrets aren't exposed anywhere
- **totp-rs** to generate and validate one-time passwords

## Goals

I wanted to have an API fully tested, allowing all these actions:

- users can signup using a username and a password
- after they are registered, the receive their recovery codes because we are not using any email
- they can use their recovery code in case they lost their password and access their account
- after they are registered, they can enable 2FA, if they accept, a QR code is sent and they have to verify it by sending a one-time password (OTP) they generated on their app
- if 2FA is enabled, users have to generate their OTP every time they connect
- users have a profile page when they can see and update their profile
- when connected, users use an access token which expires after 15 minutes and can be replaced using a refresh token which expires after 7 days

My integration tests have to ensure each of these actions are possible and that misusing them is also not possible.

## Difficulties

One difficulty when writing integration tests for API is test concurrency. In Rust, when you run **cargo test**, your tests are generally ran in parallel, which means that if they all make queries to the same database, you might end up with conflicts and your tests can randomly fail.

One way to overcome that is creating a transaction for each test and then roll it back at the end of it. This is simple and fast but not always feasible. For instance, if your views are using a state variable that is a database **pool** connection, you will struggle a lot to pass your test transaction into that, especially if your test contains many requests that depends on each other.

Another way is to use a different database for each of your tests. Ideally this database is in-memory to not have to clean it after manually. Unfortunately, I believe this is only possible for SQLite databases, not PostgreSQL ones.

The way I went for, which is pretty much inspired by [](zero2prod), is creating a new database everytime in my PostgreSQL container giving it a Uuid for the name to avoid reusing an existing database. Each of my test creates a database, gets a pool of connections, runs the migrations, and then executes itself.

Another difficulty when writing tests in Rust is being able to control the time, when your code uses **chrono::Utc::now**. Currently, these is no way to easily "freeze" the time at a moment you decide in your tests, like **freezegun.free_time** in Python. Luckily, someone started a pull request for this issue on the chrono GitHub project [https://github.com/chronotope/chrono/pull/1244/files](here). In this PR's changes, you can see this:

```rust
// Value to use for `Utc::now()` and `Local::now()`, when set with `Local::override_now`.
#[cfg(all(feature = "clock", feature = "test-override"))]
thread_local!(
    pub(super) static OVERRIDE_NOW: RefCell<Option<DateTime<FixedOffset>>> = RefCell::new(None)
);
```

This variable **OVERRIDE_NOW** is global in a thread, which means that you can set it in a test, and no other test will be impacted by it. Using that, you can you own **now** function that will whether call **Utc::now** is **OVERRIDE_NOW** is not set, otherwise **OVERRIDE_NOW**. Then, you just have to replace usage of **Utc::now()** in your code by your own function **now()**.

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

Using this trick means I cannot write my tests using an http server running in a different thread and then execute my request using the **reqwest** crate like zero2prod. Instead, and probably for the best, I can use the Actix's test utilities. I will then have to use this pattern:

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

And the good thing is, I don't to rewrite my whole App with all routes and **web::Data** variables because I created a function that defines that already in **src/startup.rs**:

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

Here is how my simplest test look like:

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

Now if I want to control time in a test to ensure my access token will be expired after the delay I decided, I can do this:

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

And that's it, I hope it was useful. Don't hesitate to leave a comment!

See you for the next article,
Thomas
