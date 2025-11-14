use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
pub struct UpdateProfileRequest {
    pub username: String,
    pub locale: String,
    pub theme: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct SetPasswordRequest {
    pub new_password: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UpdatePasswordRequest {
    pub current_password: String,
    pub new_password: String,
}

