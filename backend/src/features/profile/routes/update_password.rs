use actix_web::{post, web, HttpResponse, Responder};
use argon2::{password_hash::SaltString, Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use rand::rngs::OsRng;
use sqlx::PgPool;

use crate::{
    core::structs::responses::GenericResponse,
    features::profile::structs::{
        models::User, requests::UpdateUserPasswordRequest, responses::UserResponse,
    },
};

#[post("/update-password")]
pub async fn update_password(
    body: web::Json<UpdateUserPasswordRequest>,
    pool: web::Data<PgPool>,
    mut request_user: User,
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

    // Verify current password
    let parsed_hash = if let Ok(parsed_hash) = PasswordHash::new(&request_user.password) {
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

    request_user.password = password_hash;
    request_user.password_is_expired = false;

    let updated_user_result = sqlx::query!(
        r#"
        UPDATE users
        SET password = $1, password_is_expired = $2
        WHERE id = $3
        "#,
        request_user.password,
        request_user.password_is_expired,
        request_user.id
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
            user: request_user.to_user_data(),
        }),
        Err(_) => HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to update user".to_string(),
        }),
    }
}
