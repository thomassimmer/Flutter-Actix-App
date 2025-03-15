use crate::{
    core::{helpers::mock_now::now, structs::responses::GenericResponse},
    features::{
        auth::helpers::token::retrieve_claims_for_token,
        profile::structs::{models::User, responses::UserResponse},
    },
};
use actix_web::{get, web, HttpRequest, HttpResponse, Responder};
use chrono::{DateTime, Utc};
use sqlx::PgPool;

#[get("/me")]
pub async fn get_profile_information(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    match retrieve_claims_for_token(req, secret.to_string()) {
        Ok(claims) => {
            if now() > DateTime::<Utc>::from_timestamp(claims.exp as i64, 0).unwrap() {
                return HttpResponse::Unauthorized().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Token expired".to_string(),
                });
            }

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

            match existing_user {
                Ok(existing_user) => match existing_user {
                    Some(existing_user) => HttpResponse::Ok().json(UserResponse {
                        status: "success".to_string(),
                        user: existing_user.to_user_data(),
                    }),
                    None => HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "No user found for this token".to_string(),
                    }),
                },
                Err(_) => HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Database query error".to_string(),
                }),
            }
        }

        Err(_) => HttpResponse::Unauthorized().json(GenericResponse {
            status: "fail".to_string(),
            message: "Invalid access token".to_string(),
        }),
    }
}
