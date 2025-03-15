use crate::{
    core::{helpers::mock_now::now, structs::response::GenericResponse},
    features::auth::{
        helpers::token::generate_tokens,
        structs::{model::Claims, request::RefreshTokenRequest, response::RefreshTokenResponse},
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
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Failed to get a transaction".to_string(),
            })
        }
    };

    let refresh_token = body.refresh_token.clone();

    let decoding_key = DecodingKey::from_secret(secret.as_bytes());
    let token_data = decode::<Claims>(&refresh_token, &decoding_key, &Validation::default());

    if token_data.is_err() {
        return HttpResponse::BadRequest().json(GenericResponse {
            status: "fail".to_string(),
            message: "Invalid refresh token".to_string(),
        });
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
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to commit transaction".to_string(),
        });
    }

    match stored_token {
        Ok(Some(expires_at)) => {
            if now() > expires_at {
                return HttpResponse::Unauthorized().json(GenericResponse {
                    status: "fail".to_string(),
                    message: "Refresh token expired".to_string(),
                });
            }
        }
        _ => {
            return HttpResponse::Unauthorized().json(GenericResponse {
                status: "fail".to_string(),
                message: "Refresh token not found".to_string(),
            });
        }
    };

    // Generate a new access token
    let (new_access_token, _, new_claims) = generate_tokens(secret.as_bytes(), claims.jti);

    HttpResponse::Ok().json(RefreshTokenResponse {
        status: "success".to_string(),
        access_token: new_access_token,
        expires_in: new_claims.exp,
    })
}
