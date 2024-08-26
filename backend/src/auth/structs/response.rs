use serde::{Deserialize, Serialize};

#[derive(Serialize, Debug, Deserialize)]
pub struct UserSignupResponse {
    pub status: String,
    pub recovery_codes: Vec<String>,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: u64,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct UserLoginWhenOtpEnabledResponse {
    pub status: String,
    pub user_id: String,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct UserLoginResponse {
    pub status: String,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: u64,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct RefreshTokenResponse {
    pub status: String,
    pub access_token: String,
    pub expires_in: u64,
}

#[derive(Serialize, Deserialize)]
pub struct GenerateOtpResponse {
    pub status: String,
    pub otp_base32: String,
    pub otp_auth_url: String,
}

#[derive(Serialize, Deserialize)]
pub struct VerifyOtpResponse {
    pub status: String,
    pub otp_verified: bool,
}

#[derive(Serialize, Deserialize)]
pub struct DisableOtpResponse {
    pub status: String,
    pub otp_enabled: bool,
}
