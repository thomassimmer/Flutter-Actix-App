use actix_web::{post, web, HttpResponse, Responder};
use argon2::{password_hash::SaltString, Argon2, PasswordHasher};
use chrono::{DateTime, Utc};
use rand::{distributions::Alphanumeric, rngs::OsRng, Rng};
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    auth::helpers::token::generate_tokens,
    models::{User, UserRegisterSchema, UserToken},
    response::{GenericResponse, UserSignupResponse},
};

#[post("/register")]
pub async fn register_user(
    body: web::Json<UserRegisterSchema>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Failed to get a transaction".to_string(),
            })
        }
    };

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

    match existing_user {
        Ok(existing_user) => {
            if existing_user.is_some() {
                let error_response = GenericResponse {
                    status: "fail".to_string(),
                    message: format!("User with username: {} already exists", username_lower),
                };
                return HttpResponse::Conflict().json(error_response);
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Database query error".to_string(),
            });
        }
    }

    // Hash the password
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = match argon2.hash_password(body.password.as_bytes(), &salt) {
        Ok(hash) => hash.to_string(),
        Err(_) => {
            return HttpResponse::BadRequest().json(GenericResponse {
                status: "fail".to_string(),
                message: "Failed to hash password".to_string(),
            })
        }
    };

    // Generate recovery codes
    let mut clear_recovery_codes = Vec::new();
    let mut hashed_recovery_codes = Vec::new();
    for _ in 0..5 {
        let code: String = rand::thread_rng()
            .sample_iter(&Alphanumeric)
            .take(16)
            .map(char::from)
            .collect();

        clear_recovery_codes.push(code.clone());

        let hashed_code = match argon2.hash_password(code.as_bytes(), &salt) {
            Ok(hash) => hash.to_string(),
            Err(_) => {
                return HttpResponse::BadRequest().json(GenericResponse {
                    status: "fail".to_string(),
                    message: "Failed to hash recovery code".to_string(),
                })
            }
        };

        hashed_recovery_codes.push(hashed_code);
    }

    let new_user = User {
        id: Uuid::new_v4(),
        username: username_lower,
        password: password_hash,
        otp_enabled: false,
        otp_verified: false,
        otp_base32: None,
        otp_auth_url: None,
        created_at: Utc::now(),
        updated_at: Utc::now(),
        recovery_codes: hashed_recovery_codes.join(","),
    };

    // Insert the new user into the database
    let insert_result = sqlx::query!(
        r#"
        INSERT INTO users (id, username, password, otp_enabled, otp_verified, otp_base32, otp_auth_url, created_at, updated_at, recovery_codes)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        "#,
        new_user.id,
        new_user.username,
        new_user.password,
        new_user.otp_enabled,
        new_user.otp_verified,
        new_user.otp_base32,
        new_user.otp_auth_url,
        new_user.created_at,
        new_user.updated_at,
        new_user.recovery_codes,
    )
    .execute(&mut *transaction)
    .await;

    if insert_result.is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to insert user into the database".to_string(),
        });
    }

    let jti = Uuid::new_v4().to_string();
    let (access_token, refresh_token, claim) = generate_tokens(secret.as_bytes(), jti);

    let new_token = UserToken {
        id: Uuid::new_v4(),
        user_id: new_user.id,
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
    .execute(&mut *transaction)
    .await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to commit transaction".to_string(),
        });
    }

    if insert_result.is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to insert user token into the database".to_string(),
        });
    }

    let json_response = UserSignupResponse {
        status: "success".to_string(),
        recovery_codes: clear_recovery_codes,
        access_token,
        refresh_token,
        expires_in: new_token.expires_at.timestamp() as u64,
    };

    HttpResponse::Ok().json(json_response)
}
