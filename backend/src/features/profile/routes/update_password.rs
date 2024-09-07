use actix_web::{post, web, HttpResponse, Responder};
use argon2::{password_hash::SaltString, Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use rand::rngs::OsRng;
use sqlx::PgPool;

use crate::{
    core::structs::responses::GenericResponse,
    features::{
        auth::structs::models::Claims,
        profile::structs::{
            models::User, requests::UpdateUserPasswordRequest, responses::UserResponse,
        },
    },
};

#[post("/update-password")]
pub async fn update_password(
    body: web::Json<UpdateUserPasswordRequest>,
    pool: web::Data<PgPool>,
    claims: Claims,
) -> impl Responder {
    let jti = claims.jti;

    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Failed to get a transaction".to_string(),
            })
        }
    };

    // Check if user already exists
    let existing_user = sqlx::query_as!(
        User,
        r#"
        SELECT u.*
        FROM users u
        JOIN user_tokens ut ON u.id = ut.user_id
        WHERE ut.token_id = $1
        "#,
        jti,
    )
    .fetch_optional(&mut *transaction)
    .await;

    let mut user = match existing_user {
        Ok(existing_user) => match existing_user {
            Some(existing_user) => existing_user,
            None => {
                return HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "No user found for this token".to_string(),
                })
            }
        },
        Err(_) => {
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Database query error".to_string(),
            })
        }
    };

    // Verify current password
    let parsed_hash = if let Ok(parsed_hash) = PasswordHash::new(&user.password) {
        parsed_hash
    } else {
        return HttpResponse::BadRequest().json(GenericResponse {
            status: "fail".to_string(),
            message: "Failed to retrieve hashed password".to_string(),
        });
    };

    let argon2 = Argon2::default();
    let is_valid = argon2
        .verify_password(body.current_password.as_bytes(), &parsed_hash)
        .is_ok();

    if !is_valid {
        return HttpResponse::Forbidden().json(GenericResponse {
            status: "fail".to_string(),
            message: "Invalid username or password".to_string(),
        });
    }

    // Hash the new password
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = match argon2.hash_password(body.new_password.as_bytes(), &salt) {
        Ok(hash) => hash.to_string(),
        Err(_) => {
            return HttpResponse::BadRequest().json(GenericResponse {
                status: "fail".to_string(),
                message: "Failed to hash password".to_string(),
            })
        }
    };

    user.password = password_hash;
    user.password_is_expired = false;

    let updated_user_result = sqlx::query!(
        r#"
        UPDATE users
        SET password = $1, password_is_expired = $2
        WHERE id = $3
        "#,
        user.password,
        user.password_is_expired,
        user.id
    )
    .fetch_optional(&mut *transaction)
    .await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to commit transaction".to_string(),
        });
    }

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(UserResponse {
            status: "success".to_string(),
            user: user.to_user_data(),
        }),
        Err(_) => HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to update user".to_string(),
        }),
    }
}
