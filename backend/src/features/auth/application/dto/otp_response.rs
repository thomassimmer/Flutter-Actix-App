use serde::{Deserialize, Serialize};

#[derive(Serialize, Debug, Deserialize)]
pub struct GenerateOtpResponse {
    pub code: String,
    pub otp_base32: String,
    pub otp_auth_url: String,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct VerifyOtpResponse {
    pub code: String,
    pub otp_verified: bool,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct DisableOtpResponse {
    pub code: String,
    pub two_fa_enabled: bool,
}
