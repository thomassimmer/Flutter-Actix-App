use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
pub struct SignupRequest {
    pub username: String,
    pub password: String,
    pub locale: String,
    pub theme: String,
}

