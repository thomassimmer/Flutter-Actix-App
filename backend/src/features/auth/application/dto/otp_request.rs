use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Deserialize, Serialize)]
pub struct VerifyOtpRequest {
    pub code: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ValidateOtpRequest {
    pub code: String,
    pub user_id: Uuid,
}

