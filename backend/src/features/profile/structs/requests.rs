use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct UserUpdateRequest {
    pub username: String,
    pub locale: String,
    pub theme: String,
}

#[derive(Debug, Deserialize)]
pub struct IsOtpEnabledRequest {
    pub username: String,
}

#[derive(Debug, Deserialize)]
pub struct SetUserPasswordRequest {
    pub new_password: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateUserPasswordRequest {
    pub current_password: String,
    pub new_password: String,
}

#[derive(Deserialize)]
pub struct DeleteDeviceParams {
    pub token_id: Uuid,
}
