use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserToken {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token_id: Uuid,
    pub expires_at: DateTime<Utc>,
    pub os: Option<String>,
    pub is_mobile: Option<bool>,
    pub browser: Option<String>,
    pub app_version: Option<String>,
    pub model: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub exp: i64,
    pub jti: Uuid,
    pub user_id: Uuid,
    pub is_admin: bool,
}

