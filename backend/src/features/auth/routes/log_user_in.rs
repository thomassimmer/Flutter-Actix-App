use crate::core::helpers::mock_now::now;
use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::password::password_is_valid;
use crate::features::auth::helpers::token::generate_tokens;
use crate::features::auth::structs::models::UserToken;
use crate::features::profile::structs::models::User;
use crate::{
    features::auth::structs::requests::UserLoginRequest,
    features::auth::structs::responses::{UserLoginResponse, UserLoginWhenOtpEnabledResponse},
};
use actix_web::{post, web, HttpResponse, Responder};
use sqlx::PgPool;
use uuid::Uuid;

#[post("/login")]
pub async fn log_user_in(
    body: web::Json<UserLoginRequest>,
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

    let user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::Forbidden().json(GenericResponse {
                    status: "fail".to_string(),
                    message: "Invalid username or password".to_string(),
                });
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Database query error".to_string(),
            })
        }
    };

    if user.password_is_expired {
        return HttpResponse::BadRequest().json(GenericResponse {
            status: "fail".to_string(),
            message: "Failed to connect. Password must be changed.".to_string(),
        });
    }

    if !password_is_valid(&user, &body.password) {
        return HttpResponse::Forbidden().json(GenericResponse {
            status: "fail".to_string(),
            message: "Invalid username or password".to_string(),
        });
    }

    if user.otp_verified {
        return HttpResponse::Ok().json(UserLoginWhenOtpEnabledResponse {
            status: "success".to_string(),
            user_id: user.id.to_string(),
        });
    }

    let jti = Uuid::new_v4().to_string();
    let (access_token, refresh_token, claim) = generate_tokens(secret.as_bytes(), jti);

    let refresh_token_expires_at = now()
        .checked_add_signed(chrono::Duration::days(7)) // Access token expires in 15 minutes
        .expect("invalid timestamp");

    let new_token = UserToken {
        id: Uuid::new_v4(),
        user_id: user.id,
        token_id: claim.jti,
        expires_at: refresh_token_expires_at,
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

    HttpResponse::Ok().json(UserLoginResponse {
        status: "success".to_string(),
        access_token,
        refresh_token,
        expires_in: claim.exp,
    })
}
