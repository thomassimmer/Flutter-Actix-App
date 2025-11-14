use serde::{Deserialize, Serialize};

#[derive(Serialize, Debug, Deserialize)]
pub struct LoginResponse {
    pub code: String,
    pub access_token: String,
    pub refresh_token: String,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct LoginWhenOtpEnabledResponse {
    pub code: String,
    pub user_id: String,
}

