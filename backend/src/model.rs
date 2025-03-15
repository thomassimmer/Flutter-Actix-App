use chrono::prelude::*;
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct User {
    pub id: String,
    pub username: String,
    pub password: String,

    pub otp_enabled: bool,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub createdAt: Option<DateTime<Utc>>,
    pub updatedAt: Option<DateTime<Utc>>,

    pub recovery_codes: Vec<String>,
}

pub struct AppState {
    pub db: Arc<Mutex<Vec<User>>>,
}

impl AppState {
    pub fn init() -> AppState {
        AppState {
            db: Arc::new(Mutex::new(Vec::new())),
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct UserRegisterSchema {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct UserLoginSchema {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct GenerateOTPSchema {
    pub username: String,
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct VerifyOTPSchema {
    pub user_id: String,
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct DisableOTPSchema {
    pub user_id: String,
}
