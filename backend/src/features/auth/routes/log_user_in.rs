use crate::core::constants::errors::AppError;
use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::password::password_is_valid;
use crate::features::auth::helpers::token::generate_tokens;
use crate::features::profile::structs::models::User;
use crate::{
    features::auth::structs::requests::UserLoginRequest,
    features::auth::structs::responses::{UserLoginResponse, UserLoginWhenOtpEnabledResponse},
};
use actix_web::{post, web, HttpResponse, Responder};
use sqlx::PgPool;

#[post("/login")]
pub async fn log_user_in(
    body: web::Json<UserLoginRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response())
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

    let user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::Unauthorized()
                    .json(AppError::InvalidUsernameOrPassword.to_response());
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(AppError::DatabaseQuery.to_response())
        }
    };

    if !password_is_valid(&user, &body.password) {
        return HttpResponse::Unauthorized()
            .json(AppError::InvalidUsernameOrPassword.to_response());
    }

    if user.password_is_expired {
        return HttpResponse::Forbidden().json(GenericResponse {
            code: "PASSWORD_MUST_BE_CHANGED".to_string(),
            message: "Password must be changed".to_string(),
        });
    }

    if user.otp_verified {
        return HttpResponse::Ok().json(UserLoginWhenOtpEnabledResponse {
            code: "USER_LOGS_IN_WITH_OTP_ENABLED".to_string(),
            user_id: user.id.to_string(),
        });
    }

    let (access_token, refresh_token) =
        match generate_tokens(secret.as_bytes(), user.id, &mut transaction).await {
            Ok((access_token, refresh_token)) => (access_token, refresh_token),
            Err(_) => {
                return HttpResponse::InternalServerError()
                    .json(AppError::TokenGeneration.to_response());
            }
        };

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    HttpResponse::Ok().json(UserLoginResponse {
        code: "USER_LOGGED_IN_WITHOUT_OTP".to_string(),
        access_token,
        refresh_token,
    })
}
