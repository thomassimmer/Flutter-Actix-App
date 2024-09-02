use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct UserRegisterRequest {
    pub username: String,
    pub password: String,
    pub locale: String,
    pub theme: String,
}

#[derive(Debug, Deserialize)]
pub struct UserLoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct GenerateOtpRequest {
    pub username: String,
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct VerifyOtpRequest {
    pub code: String,
}

#[derive(Debug, Deserialize)]
pub struct ValidateOtpRequest {
    pub code: String,
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct DisableOTPRequest {
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Deserialize)]
pub struct RecoverAccountRequest {
    pub username: String,
    pub recovery_code: String,
}
