use crate::{
    core::{helpers::mock_now::now, structs::responses::GenericResponse},
    features::{
        auth::helpers::token::retrieve_claims_for_token,
        profile::structs::{
            models::User,
            requests::{IsOtpEnabledRequest, UserUpdateRequest},
            responses::{IsOtpEnabledResponse, UserResponse},
        },
    },
};
use actix_web::{get, post, web, HttpRequest, HttpResponse, Responder};
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

#[post("/me")]
pub async fn post_profile_information(
    req: HttpRequest,
    body: web::Json<UserUpdateRequest>,
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

        Err(_) => HttpResponse::Unauthorized().json(GenericResponse {
            status: "fail".to_string(),
            message: "Invalid access token".to_string(),
        }),
    }
}

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
