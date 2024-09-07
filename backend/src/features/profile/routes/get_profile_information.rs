use crate::{
    core::structs::responses::GenericResponse,
    features::{
        auth::structs::models::Claims,
        profile::structs::{models::User, responses::UserResponse},
    },
};
use actix_web::{get, web, HttpResponse, Responder};
use sqlx::PgPool;

#[get("/me")]
pub async fn get_profile_information(pool: web::Data<PgPool>, claims: Claims) -> impl Responder {
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
