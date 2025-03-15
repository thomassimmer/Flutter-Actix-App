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
    pub theme: String,

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
    pub password: String,
    pub locale: String,
    pub theme: String,

    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,

    pub recovery_codes: String,
}

impl User {
    pub fn to_user_data(&self) -> UserData {
        UserData {
            id: self.id,
            username: self.username.to_owned(),
            locale: self.locale.to_owned(),
            theme: self.theme.to_owned(),
            otp_auth_url: self.otp_auth_url.to_owned(),
            otp_base32: self.otp_base32.to_owned(),
            otp_verified: self.otp_verified,
            createdAt: self.created_at,
            updatedAt: self.updated_at,
        }
    }
}
