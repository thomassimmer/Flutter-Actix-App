use actix_web::{post, web, HttpRequest, HttpResponse, Responder};
use argon2::{password_hash::SaltString, Argon2, PasswordHasher};
use rand::{distributions::Alphanumeric, rngs::OsRng, Rng};
use sqlx::PgPool;
use tracing::error;
use uuid::Uuid;

use crate::{
    core::{
        constants::errors::AppError, helpers::mock_now::now, structs::responses::GenericResponse,
    },
    features::{
        auth::{
            helpers::{
                password::is_password_valid, token::generate_tokens, username::is_username_valid,
            },
            structs::{requests::UserRegisterRequest, responses::UserSignupResponse},
        },
        profile::{
            helpers::{
                device_info::get_user_agent,
                profile::{create_user, get_user_by_username},
            },
            structs::models::User,
        },
    },
};

#[post("/signup")]
pub async fn register_user(
    req: HttpRequest,
    body: web::Json<UserRegisterRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response());
        }
    };

    let body = body.into_inner();
    let username_lower = body.username.to_lowercase();


    let existing_user = get_user_by_username(&mut *transaction, &username_lower).await;

    match existing_user {
        Ok(existing_user) => {
            if existing_user.is_some() {
                let error_response = GenericResponse {
                    code: "USER_ALREADY_EXISTS".to_string(),
                    message: format!("User with username: {} already exists", username_lower),
                };
                return HttpResponse::Conflict().json(error_response);
            }
        }
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError().json(AppError::DatabaseQuery.to_response());
        }
    }

    // Validate username
    if let Some(exception) = is_username_valid(&body.username) {
        return HttpResponse::Unauthorized().json(exception.to_response());
    }

    // Validate password
    if let Some(exception) = is_password_valid(&body.password) {
        return HttpResponse::Unauthorized().json(exception.to_response());
    }

    // Hash the password
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = match argon2.hash_password(body.password.as_bytes(), &salt) {
        Ok(hash) => hash.to_string(),
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError().json(AppError::PasswordHash.to_response());
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
            Err(e) => {
                error!("Error: {}", e);
                return HttpResponse::InternalServerError().json(GenericResponse {
                    code: "RECOVERY_CODE_HASH".to_string(),
                    message: "Failed to hash recovery code".to_string(),
                });
            }
        };

        hashed_recovery_codes.push(hashed_code);
    }

    let new_user = User {
        id: Uuid::new_v4(),
        username: username_lower,
        password: password_hash,
        locale: body.locale,
        theme: body.theme,
        otp_verified: false,
        otp_base32: None,
        otp_auth_url: None,
        created_at: now(),
        updated_at: now(),
        recovery_codes: hashed_recovery_codes.join(";"),
        password_is_expired: false,
        is_admin: false,
    };

    // Insert the new user into the database
    let insert_result = create_user(&mut *transaction, &new_user).await;

    if let Err(e) = insert_result {
        error!("Error: {}", e);
        return HttpResponse::InternalServerError().json(GenericResponse {
            code: "USER_INSERT".to_string(),
            message: "Failed to insert user into the database".to_string(),
        });
    }

    let parsed_device_info = get_user_agent(req).await;

    let (access_token, refresh_token) = match generate_tokens(
        &mut *transaction,
        secret.as_bytes(),
        new_user.id,
        new_user.is_admin,
        parsed_device_info,
    )
    .await
    {
        Ok((access_token, refresh_token)) => (access_token, refresh_token),
        Err(e) => {
            error!("Error: {}", e);
            return HttpResponse::InternalServerError()
                .json(AppError::TokenGeneration.to_response());
        }
    };

    if let Err(e) = transaction.commit().await {
        error!("Error: {}", e);
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    let json_response = UserSignupResponse {
        code: "USER_SIGNED_UP".to_string(),
        recovery_codes: clear_recovery_codes,
        access_token,
        refresh_token,
    };

    HttpResponse::Created().json(json_response)
}
