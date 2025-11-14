use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Device {
    pub token_id: Uuid,
    pub user_id: Uuid,
    pub os: Option<String>,
    pub is_mobile: Option<bool>,
    pub browser: Option<String>,
    pub app_version: Option<String>,
    pub model: Option<String>,
    pub expires_at: DateTime<Utc>,
    pub last_activity: Option<DateTime<Utc>>,
}

