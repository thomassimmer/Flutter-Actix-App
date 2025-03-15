use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::models::{ParsedDeviceInfo, UserData};

#[derive(Serialize, Deserialize)]
pub struct UserResponse {
    pub code: String,
    pub user: UserData,
}

#[derive(Serialize, Deserialize)]
pub struct IsOtpEnabledResponse {
    pub code: String,
    pub otp_enabled: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DeviceData {
    pub token_id: Uuid,
    pub parsed_device_info: ParsedDeviceInfo,
    pub last_activity_date: Option<DateTime<Utc>>,
}

#[derive(Serialize, Deserialize)]
pub struct DevicesResponse {
    pub code: String,
    pub devices: Vec<DeviceData>,
}

#[derive(Serialize, Deserialize)]
pub struct DeviceDeleteResponse {
    pub code: String,
}
