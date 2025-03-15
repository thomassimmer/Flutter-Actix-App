use crate::{
    models::{Claims, User},
    response::{user_to_response, UserResponse},
};
use actix_web::{web, HttpRequest, HttpResponse, Responder};
use chrono::{offset, DateTime, Utc};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde_json::json;
use sqlx::PgPool;

pub async fn get_profile_information(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let auth_header = match req.headers().get("Authorization") {
        Some(header_value) => header_value.to_str().ok(),
        None => None,
    };

    if let Some(auth_header) = auth_header {
        if auth_header.starts_with("Bearer ") {
            let token = &auth_header[7..]; // Strip "Bearer " from the token

            let decoding_key = DecodingKey::from_secret(secret.as_bytes());
            let token_data = decode::<Claims>(token, &decoding_key, &Validation::default());

            match token_data {
                Ok(token_data) => {
                    if offset::Utc::now()
                        > DateTime::<Utc>::from_timestamp(token_data.claims.exp as i64, 0).unwrap()
                    {
                        return HttpResponse::Unauthorized()
                            .json(json!({"status": "error", "message": "Token expired"}));
                    }

                    let jti = token_data.claims.jti;

                    let transaction = pool.begin().await;

                    if let Err(_) = transaction {
                        return HttpResponse::InternalServerError()
                            .json(json!({"status": "error", "message": "Failed to get a database connection"}));
                    }

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
                    .fetch_optional(&mut *transaction.unwrap())
                    .await;

                    match existing_user {
                        Ok(existing_user) => match existing_user {
                            Some(existing_user) => {
                                return HttpResponse::Ok().json(UserResponse {
                                    status: "success".to_string(),
                                    user: user_to_response(&existing_user),
                                });
                            }
                            None => {}
                        },
                        Err(e) => {
                            println!("{:?}", e);
                            return HttpResponse::InternalServerError().json(
                                json!({"status": "error", "message": "Database query error"}),
                            );
                        }
                    }
                }
                Err(e) => {
                    println!("{}", e);
                }
            }
        }
    }

    HttpResponse::Unauthorized().json(json!({
        "status": "fail",
        "message": "Invalid or missing access token"
    }))
}
