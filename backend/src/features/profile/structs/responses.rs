use serde::{Deserialize, Serialize};

use super::models::UserData;

#[derive(Serialize, Deserialize)]
pub struct UserResponse {
    pub status: String,
    pub user: UserData,
}

#[derive(Serialize, Deserialize)]
pub struct IsOtpEnabledResponse {
    pub status: String,
    pub otp_enabled: bool,
}
