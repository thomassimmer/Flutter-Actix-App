use actix_web::HttpRequest;
use chrono::{DateTime, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use sha2::{Digest, Sha256};
use sqlx::Error;
use sqlx::{postgres::PgQueryResult, PgConnection};
use uuid::Uuid;

use crate::features::profile::structs::models::ParsedDeviceInfo;
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
    is_admin: bool,
    parsed_device_info: ParsedDeviceInfo,
    transaction: &mut PgConnection,
) -> Result<(String, String), Error> {
    let jti = Uuid::new_v4();

    let (access_token, _) = generate_access_token(secret_key, jti, user_id, is_admin);
    let (refresh_token, refresh_token_expires_at) =
        generate_refresh_token(secret_key, jti, user_id, is_admin);

    save_tokens(
        user_id,
        jti,
        refresh_token_expires_at,
        parsed_device_info,
        transaction,
    )
    .await
    .unwrap();

    Ok((access_token, refresh_token))
}

pub fn generate_access_token(
    secret_key: &[u8],
    jti: Uuid,
    user_id: Uuid,
    is_admin: bool,
) -> (String, DateTime<Utc>) {
    let access_token_expires_at = now()
        .checked_add_signed(chrono::Duration::minutes(15)) // Access token expires in 15 minutes
        .expect("invalid timestamp");

    let access_claims = Claims {
        exp: access_token_expires_at.timestamp(),
        jti,
        user_id,
        is_admin,
    };

    let access_token = encode(
        &Header::default(),
        &access_claims,
        &EncodingKey::from_secret(secret_key),
    )
    .expect("Token creation failed");

    (access_token, access_token_expires_at)
}

pub fn generate_refresh_token(
    secret_key: &[u8],
    jti: Uuid,
    user_id: Uuid,
    is_admin: bool,
) -> (String, DateTime<Utc>) {
    let refresh_token_expires_at = now()
        .checked_add_signed(chrono::Duration::days(7)) // Refresh token expires in 7 days
        .expect("invalid timestamp");

    let refresh_claims = Claims {
        exp: refresh_token_expires_at.timestamp(),
        jti,
        user_id,
        is_admin,
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
    jti: Uuid,
    refresh_claim_expires_at: DateTime<Utc>,
    parsed_device_info: ParsedDeviceInfo,
    transaction: &mut PgConnection,
) -> Result<PgQueryResult, Error> {
    let new_token = UserToken {
        id: Uuid::new_v4(),
        user_id,
        token_id: jti,
        expires_at: refresh_claim_expires_at,
        os: parsed_device_info.os,
        is_mobile: parsed_device_info.is_mobile,
        browser: parsed_device_info.browser,
        app_version: parsed_device_info.app_version,
        model: parsed_device_info.model,
    };

    // Insert the new user token into the database
    sqlx::query!(
        r#"
        INSERT INTO user_tokens (id, user_id, token_id, expires_at, os, is_mobile, browser, app_version, model)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        "#,
        new_token.id,
        new_token.user_id,
        new_token.token_id,
        new_token.expires_at,
        new_token.os,
        new_token.is_mobile,
        new_token.browser,
        new_token.app_version,
        new_token.model
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

pub async fn delete_token(
    token_id: Uuid,
    transaction: &mut PgConnection,
) -> Result<PgQueryResult, Error> {
    sqlx::query!(
        r#"
        DELETE
        FROM user_tokens
        WHERE token_id = $1
        "#,
        token_id
    )
    .execute(transaction)
    .await
}

pub async fn get_user_token(
    user_id: Uuid,
    token_id: Uuid,
    transaction: &mut PgConnection,
) -> Result<Option<UserToken>, Error> {
    sqlx::query_as!(
        UserToken,
        r#"
        SELECT *
        FROM user_tokens
        WHERE user_id = $1 and token_id = $2
        "#,
        user_id,
        token_id,
    )
    .fetch_optional(transaction)
    .await
}

pub async fn get_user_tokens(
    user_id: Uuid,
    transaction: &mut PgConnection,
) -> Result<Vec<UserToken>, Error> {
    sqlx::query_as!(
        UserToken,
        r#"
        SELECT *
        FROM user_tokens
        WHERE user_id = $1
        "#,
        user_id
    )
    .fetch_all(transaction)
    .await
}
