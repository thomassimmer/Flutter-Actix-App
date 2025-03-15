use serde::{Deserialize, Serialize};
use sqlx::prelude::FromRow;

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, FromRow)]
pub struct User {
    pub id: uuid::Uuid,
    pub username: String,
    pub password: String,

    pub otp_enabled: bool,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,

    pub recovery_codes: String,
}

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, FromRow)]
pub struct UserToken {
    pub id: uuid::Uuid,
    pub user_id: uuid::Uuid,
    pub token_id: String,
    pub expires_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub exp: u64,
    pub jti: String,
}

#[derive(Debug, Deserialize)]
pub struct UserRegisterSchema {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct UserLoginSchema {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct GenerateOTPSchema {
    pub username: String,
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct VerifyOTPSchema {
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct ValidateOTPSchema {
    pub token: String,
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct DisableOTPSchema {
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}
