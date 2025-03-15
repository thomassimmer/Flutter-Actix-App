use crate::{
    core::structs::responses::GenericResponse,
    features::profile::structs::{
        models::User, requests::UserUpdateRequest, responses::UserResponse,
    },
};
use actix_web::{post, web, HttpResponse, Responder};
use sqlx::PgPool;

#[post("/me")]
pub async fn post_profile_information(
    body: web::Json<UserUpdateRequest>,
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

    request_user.username = body.username.clone();
    request_user.locale = body.locale.clone();
    request_user.theme = body.theme.clone();

    let updated_user_result = sqlx::query!(
        r#"
        UPDATE users
        SET username = $1, locale = $2, theme = $3
        WHERE id = $4
        "#,
        request_user.username,
        request_user.locale,
        request_user.theme,
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
