use serde::{Deserialize, Serialize};

#[derive(Serialize, Debug, Deserialize)]
pub struct IsOtpEnabledResponse {
    pub code: String,
    pub otp_enabled: bool,
}
