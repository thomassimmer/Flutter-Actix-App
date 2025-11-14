use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Serialize, Debug, Deserialize)]
pub struct UserData {
    pub id: Uuid,
    pub username: String,
    pub locale: String,
    pub theme: String,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<Utc>,
    #[serde(rename = "updatedAt")]
    pub updated_at: DateTime<Utc>,
    pub password_is_expired: bool,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct ProfileResponse {
    pub code: String,
    pub user: UserData,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct DeviceInfo {
    pub os: Option<String>,
    pub is_mobile: Option<bool>,
    pub browser: Option<String>,
    pub app_version: Option<String>,
    pub model: Option<String>,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct DeviceData {
    pub token_id: Uuid,
    pub parsed_device_info: DeviceInfo,
    pub last_activity_date: Option<DateTime<Utc>>,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct DevicesResponse {
    pub code: String,
    pub devices: Vec<DeviceData>,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct DeviceDeleteResponse {
    pub code: String,
}

