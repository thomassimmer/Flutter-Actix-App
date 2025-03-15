use actix_web::HttpRequest;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use sha2::{Digest, Sha256};

use crate::{auth::structs::model::Claims, core::helpers::mock_now::now};

use super::error::AuthError;

pub fn hash_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token);
    format!("{:X}", hasher.finalize())
}

pub fn generate_tokens(secret_key: &[u8], jti: String) -> (String, String, Claims) {
    let exp = now()
        .checked_add_signed(chrono::Duration::minutes(15)) // Access token expires in 15 minutes
        .expect("invalid timestamp")
        .timestamp();

    let claims = Claims {
        exp: exp as u64,
        jti,
    };

    let access_token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret_key),
    )
    .expect("Token creation failed");

    let refresh_token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret_key),
    )
    .expect("Token creation failed");

    (access_token, refresh_token, claims)
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
                Err(e) => Err(AuthError::TokenDecodingError(e)),
            }
        } else {
            Err(AuthError::InvalidAuthHeader)
        }
    } else {
        Err(AuthError::MissingAuthHeader)
    }
}
