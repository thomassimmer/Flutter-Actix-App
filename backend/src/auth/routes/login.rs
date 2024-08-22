use crate::auth::helpers::token::generate_tokens;
use crate::models::UserToken;
use crate::{
    models::{User, UserLoginSchema},
    response::{UserLoginWhenOtpDisabledResponse, UserLoginWhenOtpEnabledResponse},
};
use actix_web::{web, HttpResponse, Responder};
use argon2::{
    password_hash::{PasswordHash, PasswordVerifier},
    Argon2,
};
use chrono::{DateTime, Utc};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

pub async fn log_user_in(
    body: web::Json<UserLoginSchema>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = pool
        .begin()
        .await
        .expect("Failed to acquire a Postgres connection from the pool");

    let body = body.into_inner();
    let username_lower = body.username.to_lowercase();

    // Check if user already exists
    let existing_user = sqlx::query_as!(
        User,
        r#"
        SELECT *
        FROM users
        WHERE username = $1
        "#,
        username_lower,
    )
    .fetch_optional(&mut *transaction)
    .await;

    let user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::BadRequest()
                    .json(json!({"status": "fail", "message": "Invalid email or password"}));
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Database query error"}))
        }
    };

    let parsed_hash = if let Ok(parsed_hash) = PasswordHash::new(&user.password) {
        parsed_hash
    } else {
        return HttpResponse::BadRequest()
            .json(json!({"status": "fail", "message": "Failed to retrieve hashed password"}));
    };

    let argon2 = Argon2::default();

    let is_valid = argon2
        .verify_password(body.password.as_bytes(), &parsed_hash)
        .is_ok();

    if !is_valid {
        return HttpResponse::BadRequest()
            .json(json!({"status": "fail", "message": "Invalid username or password"}));
    }

    if user.otp_enabled {
        return HttpResponse::Ok().json(UserLoginWhenOtpEnabledResponse {
            status: "success".to_string(),
            user_id: user.id.to_string(),
        });
    }

    let jti = Uuid::new_v4().to_string();
    let (access_token, refresh_token, claim) = generate_tokens(secret.as_bytes(), jti);

    let new_token = UserToken {
        id: Uuid::new_v4(),
        user_id: user.id.clone(),
        token_id: claim.jti,
        expires_at: DateTime::<Utc>::from_timestamp(claim.exp as i64, 0).unwrap(),
    };

    // Insert the new user token into the database
    let insert_result = sqlx::query!(
        r#"
        INSERT INTO user_tokens (id, user_id, token_id, expires_at)
        VALUES ($1, $2, $3, $4)
        "#,
        new_token.id,
        new_token.user_id,
        new_token.token_id,
        new_token.expires_at,
    )
    .execute(pool.get_ref())
    .await;

    if let Err(e) = insert_result {
        println!("{:?}", e);
        return HttpResponse::InternalServerError().json(
            serde_json::json!({"status": "error", "message": "Failed to insert user token into the database"}),
        );
    }

    return HttpResponse::Ok().json(UserLoginWhenOtpDisabledResponse {
        status: "success".to_string(),
        access_token,
        refresh_token,
        expires_in: claim.exp,
    });
}
