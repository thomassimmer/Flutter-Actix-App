use actix_web::HttpRequest;
use chrono::{DateTime, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use sha2::{Digest, Sha256};
use sqlx::Error;
use sqlx::{postgres::PgQueryResult, PgConnection};
use uuid::Uuid;

use crate::{
    core::helpers::mock_now::now,
    features::auth::structs::models::{Claims, UserToken},
};

use super::errors::AuthError;

pub fn hash_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token);
    format!("{:X}", hasher.finalize())
}

pub async fn generate_tokens(
    secret_key: &[u8],
    user_id: Uuid,
    transaction: &mut PgConnection,
) -> Result<(String, String), Error> {
    let jti = Uuid::new_v4().to_string();

    let (access_token, _) = generate_access_token(secret_key, &jti);
    let (refresh_token, refresh_token_expires_at) = generate_refresh_token(secret_key, &jti);

    save_tokens(user_id, jti, refresh_token_expires_at, transaction)
        .await
        .unwrap();

    Ok((access_token, refresh_token))
}

pub fn generate_access_token(secret_key: &[u8], jti: &str) -> (String, DateTime<Utc>) {
    let access_token_expires_at = now()
        .checked_add_signed(chrono::Duration::minutes(15)) // Access token expires in 15 minutes
        .expect("invalid timestamp");

    let access_claims = Claims {
        exp: access_token_expires_at.timestamp(),
        jti: jti.to_string(),
    };

    let access_token = encode(
        &Header::default(),
        &access_claims,
        &EncodingKey::from_secret(secret_key),
    )
    .expect("Token creation failed");

    (access_token, access_token_expires_at)
}

pub fn generate_refresh_token(secret_key: &[u8], jti: &str) -> (String, DateTime<Utc>) {
    let refresh_token_expires_at = now()
        .checked_add_signed(chrono::Duration::days(7)) // Refresh token expires in 7 days
        .expect("invalid timestamp");

    let refresh_claims = Claims {
        exp: refresh_token_expires_at.timestamp(),
        jti: jti.to_string(),
    };

    let refresh_token = encode(
        &Header::default(),
        &refresh_claims,
        &EncodingKey::from_secret(secret_key),
    )
    .expect("Token creation failed");

    (refresh_token, refresh_token_expires_at)
}

pub async fn save_tokens(
    user_id: Uuid,
    jti: String,
    refresh_claim_expires_at: DateTime<Utc>,
    transaction: &mut PgConnection,
) -> Result<PgQueryResult, Error> {
    let new_token = UserToken {
        id: Uuid::new_v4(),
        user_id,
        token_id: jti,
        expires_at: refresh_claim_expires_at,
    };

    // Insert the new user token into the database
    sqlx::query!(
        r#"
        INSERT INTO user_tokens (id, user_id, token_id, expires_at)
        VALUES ($1, $2, $3, $4)
        "#,
        new_token.id,
        new_token.user_id,
        new_token.token_id,
        new_token.expires_at,
    )
    .execute(transaction)
    .await
}

pub fn retrieve_claims_for_token(req: HttpRequest, secret: String) -> Result<Claims, AuthError> {
    let auth_header = match req.headers().get("Authorization") {
        Some(header_value) => header_value.to_str().ok(),
        None => None,
    };

    if let Some(auth_header) = auth_header {
        if let Some(token) = auth_header.strip_prefix("Bearer ") {
            let decoding_key = DecodingKey::from_secret(secret.as_bytes());
            let token_data = decode::<Claims>(token, &decoding_key, &Validation::default());

            match token_data {
                Ok(token_data) => Ok(token_data.claims),
                Err(e) => Err(AuthError::TokenDecodingError(e)), // TODO
            }
        } else {
            Err(AuthError::InvalidAuthHeader)
        }
    } else {
        Err(AuthError::MissingAuthHeader)
    }
}
