use jsonwebtoken::{encode, EncodingKey, Header};
use sha2::{Digest, Sha256};

use crate::models::Claims;

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
