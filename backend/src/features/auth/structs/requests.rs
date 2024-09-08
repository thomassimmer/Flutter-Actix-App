use serde::Deserialize;
use uuid::Uuid;

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
pub struct VerifyOtpRequest {
    pub code: String,
}

#[derive(Debug, Deserialize)]
pub struct ValidateOtpRequest {
    pub code: String,
    pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Deserialize)]
pub struct RecoverAccountUsingPasswordRequest {
    pub username: String,
    pub password: String,
    pub recovery_code: String,
}

#[derive(Debug, Deserialize)]
pub struct RecoverAccountUsing2FARequest {
    pub username: String,
    pub code: String,
    pub recovery_code: String,
}

#[derive(Debug, Deserialize)]
pub struct RecoverAccountWithout2FAEnabledRequest {
    pub username: String,
    pub recovery_code: String,
}
