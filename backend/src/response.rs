use chrono::prelude::*;
use serde::Serialize;

#[derive(Serialize)]
pub struct GenericResponse {
    pub status: String,
    pub message: String,
}

#[allow(non_snake_case)]
#[derive(Serialize, Debug)]
pub struct UserData {
    pub id: String,
    pub username: String,

    pub otp_enabled: bool,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub createdAt: DateTime<Utc>,
    pub updatedAt: DateTime<Utc>,
}

#[derive(Serialize, Debug)]
pub struct UserSignupResponse {
    pub status: String,
    pub user: UserData,
    pub recovery_codes: Vec<String>,
}

#[derive(Serialize, Debug)]
pub struct UserLoginWhenOtpEnabledResponse {
    pub status: String,
    pub user_id: String,
}

#[derive(Serialize, Debug)]
pub struct UserLoginWhenOtpDisabledResponse {
    pub status: String,
    pub user: UserData,
}
