use serde::{Deserialize, Serialize};

#[derive(Serialize, Debug, Deserialize)]
pub struct SignupResponse {
    pub code: String,
    pub recovery_codes: Vec<String>,
    pub access_token: String,
    pub refresh_token: String,
}

