use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::prelude::FromRow;
use uuid::Uuid;

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, FromRow)]
pub struct UserModel {
    pub id: Uuid,
    pub username: String,
    pub password: String,
    pub locale: String,
    pub theme: String,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,
    pub password_is_expired: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<UserModel> for crate::features::profile::domain::entities::User {
    fn from(model: UserModel) -> Self {
        Self {
            id: model.id,
            username: model.username,
            password_hash: model.password,
            locale: model.locale,
            theme: model.theme,
            otp_verified: model.otp_verified,
            otp_base32: model.otp_base32,
            otp_auth_url: model.otp_auth_url,
            password_is_expired: model.password_is_expired,
            created_at: model.created_at,
            updated_at: model.updated_at,
        }
    }
}

impl From<crate::features::profile::domain::entities::User> for UserModel {
    fn from(entity: crate::features::profile::domain::entities::User) -> Self {
        Self {
            id: entity.id,
            username: entity.username,
            password: entity.password_hash,
            locale: entity.locale,
            theme: entity.theme,
            otp_verified: entity.otp_verified,
            otp_base32: entity.otp_base32,
            otp_auth_url: entity.otp_auth_url,
            password_is_expired: entity.password_is_expired,
            created_at: entity.created_at,
            updated_at: entity.updated_at,
        }
    }
}

