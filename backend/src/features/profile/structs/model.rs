use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::prelude::FromRow;
use uuid::Uuid;

#[allow(non_snake_case)]
#[derive(Serialize, Debug, Deserialize)]
pub struct UserData {
    pub id: Uuid,
    pub username: String,
    pub locale: String,

    pub otp_enabled: bool,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub createdAt: DateTime<Utc>,
    pub updatedAt: DateTime<Utc>,
}

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, FromRow)]
pub struct User {
    pub id: uuid::Uuid,
    pub username: String,
    pub locale: String,
    pub password: String,

    pub otp_enabled: bool,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,

    pub recovery_codes: String,
}
