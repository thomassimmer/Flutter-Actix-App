use serde::{Deserialize, Serialize};

#[derive(Serialize, Debug, Deserialize)]
pub struct RefreshTokenResponse {
    pub code: String,
    pub access_token: String,
    pub refresh_token: String,
}