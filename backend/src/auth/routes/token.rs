use crate::{
    auth::helpers::token::generate_tokens,
    models::{Claims, RefreshTokenRequest},
    response::RefreshTokenResponse,
};
use actix_web::{web, HttpResponse, Responder};
use chrono::offset;
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde_json::json;
use sqlx::PgPool;

pub async fn refresh_token(
    body: web::Json<RefreshTokenRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = pool
        .begin()
        .await
        .expect("Failed to acquire a Postgres connection from the pool");

    let refresh_token = body.refresh_token.clone();

    let decoding_key = DecodingKey::from_secret(secret.as_bytes());
    let token_data = decode::<Claims>(&refresh_token, &decoding_key, &Validation::default());

    if let Err(_) = token_data {
        return HttpResponse::BadRequest()
            .json(json!({"status": "fail", "message": "Invalid refresh token"}));
    }

    let claims = token_data.unwrap().claims;

    // Check if the refresh token exists in the database
    let stored_token = sqlx::query_scalar!(
        r#"
        SELECT expires_at
        FROM user_tokens
        WHERE token_id = $1
        "#,
        claims.jti
    )
    .fetch_optional(&mut *transaction)
    .await;

    match stored_token {
        Ok(Some(expires_at)) => {
            if offset::Utc::now() > expires_at {
                return HttpResponse::Unauthorized()
                    .json(json!({"status": "fail", "message": "Refresh token expired"}));
            }
        }
        _ => {
            return HttpResponse::Unauthorized()
                .json(json!({"status": "fail", "message": "Refresh token not found"}))
        }
    };

    // Generate a new access token
    let (new_access_token, _, new_claims) = generate_tokens(secret.as_bytes(), claims.jti);

    return HttpResponse::Ok().json(RefreshTokenResponse {
        status: "success".to_string(),
        access_token: new_access_token,
        expires_in: new_claims.exp,
    });
}
