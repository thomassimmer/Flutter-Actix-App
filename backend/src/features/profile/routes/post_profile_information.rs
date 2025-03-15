use crate::{
    core::structs::responses::GenericResponse,
    features::{
        auth::structs::models::Claims,
        profile::structs::{models::User, requests::UserUpdateRequest, responses::UserResponse},
    },
};
use actix_web::{post, web, HttpResponse, Responder};
use sqlx::PgPool;

#[post("/me")]
pub async fn post_profile_information(
    body: web::Json<UserUpdateRequest>,
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

    user.username = body.username.clone();
    user.locale = body.locale.clone();
    user.theme = body.theme.clone();

    let updated_user_result = sqlx::query!(
        r#"
        UPDATE users
        SET username = $1, locale = $2, theme = $3
        WHERE id = $4
        "#,
        user.username,
        user.locale,
        user.theme,
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
