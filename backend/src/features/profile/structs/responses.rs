use serde::{Deserialize, Serialize};

use super::models::UserData;

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
