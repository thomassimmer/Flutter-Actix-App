use crate::{
    core::constants::errors::AppError,
    features::{
        auth::structs::models::Claims,
        profile::{
            helpers::profile::get_user,
            structs::{requests::UserUpdateRequest, responses::UserResponse},
        },
    },
};
use actix_web::{
    post,
    web::{self, ReqData},
    HttpResponse, Responder,
};
use sqlx::PgPool;

#[post("/me")]
pub async fn post_profile_information(
    body: web::Json<UserUpdateRequest>,
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
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(UserResponse {
            code: "PROFILE_UPDATED".to_string(),
            user: request_user.to_user_data(),
        }),
        Err(_) => HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response()),
    }
}
