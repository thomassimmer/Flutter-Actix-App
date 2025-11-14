use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
pub struct RecoverAccountWithout2FAEnabledRequest {
    pub username: String,
    pub recovery_code: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct RecoverAccountUsingPasswordRequest {
    pub username: String,
    pub password: String,
    pub recovery_code: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct RecoverAccountUsing2FARequest {
    pub username: String,
    pub code: String,
    pub recovery_code: String,
}
