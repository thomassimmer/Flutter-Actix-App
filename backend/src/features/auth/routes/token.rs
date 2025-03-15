use crate::{
    core::{
        constants::errors::AppError, helpers::mock_now::now, structs::responses::GenericResponse,
    },
    features::auth::{
        helpers::token::generate_access_token,
        structs::{models::Claims, requests::RefreshTokenRequest, responses::RefreshTokenResponse},
    },
};
use actix_web::{post, web, HttpResponse, Responder};
use jsonwebtoken::{decode, DecodingKey, Validation};
use sqlx::PgPool;

#[post("/refresh-token")]
pub async fn refresh_token(
    body: web::Json<RefreshTokenRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response())
        }
    };

    let refresh_token = body.refresh_token.clone();

    let decoding_key = DecodingKey::from_secret(secret.as_bytes());
    let token_data = decode::<Claims>(&refresh_token, &decoding_key, &Validation::default());

    if token_data.is_err() {
        return HttpResponse::Unauthorized().json(AppError::InvalidRefreshToken.to_response());
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

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    match stored_token {
        Ok(Some(expires_at)) => {
            if now() > expires_at {
                return HttpResponse::Unauthorized().json(GenericResponse {
                    code: "REFRESH_TOKEN_EXPIRED".to_string(),
                    message: "Refresh token expired".to_string(),
                });
            }
        }
        _ => {
            return HttpResponse::Unauthorized().json(AppError::InvalidRefreshToken.to_response());
        }
    };

    // Generate a new access token
    let (new_access_token, _) = generate_access_token(secret.as_bytes(), &claims.jti);

    HttpResponse::Ok().json(RefreshTokenResponse {
        code: "TOKEN_REFRESHED".to_string(),
        access_token: new_access_token,
    })
}
