use actix_web::HttpRequest;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use sha2::{Digest, Sha256};

use crate::models::Claims;

use super::errors::AuthError;

pub fn hash_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token);
    format!("{:X}", hasher.finalize())
}

pub fn generate_tokens(secret_key: &[u8], jti: String) -> (String, String, Claims) {
    let exp = chrono::Utc::now()
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
        if auth_header.starts_with("Bearer ") {
            let token = &auth_header[7..]; // Strip "Bearer " from the token

            let decoding_key = DecodingKey::from_secret(secret.as_bytes());
            let token_data = decode::<Claims>(token, &decoding_key, &Validation::default());

            match token_data {
                Ok(token_data) => return Ok(token_data.claims),
                Err(e) => return Err(AuthError::TokenDecodingError(e)),
            }
        } else {
            return Err(AuthError::InvalidAuthHeader);
        }
    } else {
        return Err(AuthError::MissingAuthHeader);
    }
}
