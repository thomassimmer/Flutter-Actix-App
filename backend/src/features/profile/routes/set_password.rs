use actix_web::{
    post,
    web::{self, ReqData},
    HttpResponse, Responder,
};
use argon2::{password_hash::SaltString, Argon2, PasswordHasher};
use rand::rngs::OsRng;
use sqlx::PgPool;

use crate::{
    core::{constants::errors::AppError, structs::responses::GenericResponse},
    features::{
        auth::{
            helpers::password::{password_is_long_enough, password_is_strong_enough},
            structs::models::Claims,
        },
        profile::{
            helpers::profile::get_user,
            structs::{requests::SetUserPasswordRequest, responses::UserResponse},
        },
    },
};

#[post("/set-password")]
pub async fn set_password(
    body: web::Json<SetUserPasswordRequest>,
    pool: web::Data<PgPool>,
    request_claims: ReqData<Claims>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response())
        }
    };

    let mut request_user = match get_user(request_claims.user_id, &mut transaction).await {
        Ok(user) => match user {
            Some(user) => user,
            None => return HttpResponse::NotFound().json(AppError::UserNotFound.to_response()),
        },
        Err(_) => {
            return HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response())
        }
    };

    if !request_user.password_is_expired {
        return HttpResponse::Forbidden().json(GenericResponse {
            code: "PASSWORD_NOT_EXPIRED".to_string(),
            message: "Password is not expired. You cannot set it here.".to_string(),
        });
    }

    // Validate new password
    if !password_is_long_enough(&body.new_password) {
        let error_response = GenericResponse {
            code: "PASSWORD_TOO_SHORT".to_string(),
            message: "This password is too short.".to_string(),
        };
        return HttpResponse::Unauthorized().json(error_response);
    }
    if !password_is_strong_enough(&body.new_password) {
        let error_response = GenericResponse {
            code: "PASSWORD_TOO_WEAK".to_string(),
            message: "This password is too weak.".to_string(),
        };
        return HttpResponse::Unauthorized().json(error_response);
    }

    // Hash the new password
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = match argon2.hash_password(body.new_password.as_bytes(), &salt) {
        Ok(hash) => hash.to_string(),
        Err(_) => {
            return HttpResponse::InternalServerError().json(AppError::PasswordHash.to_response())
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
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(UserResponse {
            code: "PASSWORD_CHANGED".to_string(),
            user: request_user.to_user_data(),
        }),
        Err(_) => HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response()),
    }
}
