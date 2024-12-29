use crate::{
    core::{
        constants::errors::AppError, helpers::mock_now::now, structs::responses::GenericResponse,
    },
    features::{
        auth::{
            helpers::token::{
                delete_token, generate_access_token, generate_refresh_token, save_tokens,
            },
            structs::{
                models::{Claims, TokenCache},
                requests::RefreshTokenRequest,
                responses::RefreshTokenResponse,
            },
        },
        profile::helpers::device_info::get_user_agent,
    },
};
use actix_web::{post, web, HttpRequest, HttpResponse, Responder};
use jsonwebtoken::{decode, DecodingKey, Validation};
use sqlx::PgPool;
use uuid::Uuid;

#[post("/refresh-token")]
pub async fn refresh_token(
    req: HttpRequest,
    body: web::Json<RefreshTokenRequest>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
    cached_tokens: web::Data<TokenCache>,
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

    // Remove token and create a new one so the user never has to
    // connect again, unless after 7 days of inactivity.
    if (delete_token(claims.jti, &mut transaction).await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    cached_tokens.remove_key(claims.jti).await;

    let new_jti = Uuid::new_v4();

    let (new_access_token, _) =
        generate_access_token(secret.as_bytes(), new_jti, claims.user_id, claims.is_admin);
    let (new_refresh_token, refresh_token_expires_at) =
        generate_refresh_token(secret.as_bytes(), new_jti, claims.user_id, claims.is_admin);
    let parsed_device_info = get_user_agent(req).await;

    if (save_tokens(
        claims.user_id,
        new_jti,
        refresh_token_expires_at,
        parsed_device_info,
        &mut transaction,
    )
    .await)
        .is_err()
    {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    cached_tokens.update_or_insert_key(new_jti, now()).await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    HttpResponse::Ok().json(RefreshTokenResponse {
        code: "TOKEN_REFRESHED".to_string(),
        access_token: new_access_token,
        refresh_token: new_refresh_token,
    })
}
