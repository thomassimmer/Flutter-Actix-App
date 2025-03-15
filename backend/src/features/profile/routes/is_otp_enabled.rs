use crate::{
    core::structs::responses::GenericResponse,
    features::profile::structs::{
        models::User, requests::IsOtpEnabledRequest, responses::IsOtpEnabledResponse,
    },
};
use actix_web::{post, web, HttpResponse, Responder};
use sqlx::PgPool;

#[post("/is-otp-enabled")]
pub async fn is_otp_enabled(
    body: web::Json<IsOtpEnabledRequest>,
    pool: web::Data<PgPool>,
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

    // Check if user already exists
    let existing_user = sqlx::query_as!(
        User,
        r#"
        SELECT *
        FROM users
        WHERE username = $1
        "#,
        body.username,
    )
    .fetch_optional(&mut *transaction)
    .await;

    match existing_user {
        Ok(existing_user) => match existing_user {
            Some(existing_user) => HttpResponse::Ok().json(IsOtpEnabledResponse {
                status: "success".to_string(),
                otp_enabled: existing_user.otp_verified,
            }),
            // If user does not exist, say false to avoid scrapping usernames
            None => HttpResponse::Ok().json(IsOtpEnabledResponse {
                status: "success".to_string(),
                otp_enabled: false,
            }),
        },
        Err(_) => HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Database query error".to_string(),
        }),
    }
}
