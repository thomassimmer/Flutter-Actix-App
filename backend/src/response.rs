use chrono::prelude::*;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models::User;

#[derive(Serialize, Deserialize)]
pub struct GenericResponse {
    pub status: String,
    pub message: String,
}

#[allow(non_snake_case)]
#[derive(Serialize, Debug, Deserialize)]
pub struct UserData {
    pub id: Uuid,
    pub username: String,

    pub otp_enabled: bool,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub createdAt: DateTime<Utc>,
    pub updatedAt: DateTime<Utc>,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct UserSignupResponse {
    pub status: String,
    pub recovery_codes: Vec<String>,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: u64,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct UserLoginWhenOtpEnabledResponse {
    pub status: String,
    pub user_id: String,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct UserLoginResponse {
    pub status: String,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: u64,
}

#[derive(Serialize, Debug, Deserialize)]
pub struct RefreshTokenResponse {
    pub status: String,
    pub access_token: String,
    pub expires_in: u64,
}

#[derive(Serialize, Deserialize)]
pub struct UserResponse {
    pub status: String,
    pub user: UserData,
}

#[derive(Serialize, Deserialize)]
pub struct GenerateOtpResponse {
    pub status: String,
    pub otp_base32: String,
    pub otp_auth_url: String,
}

#[derive(Serialize, Deserialize)]
pub struct VerifyOtpResponse {
    pub status: String,
    pub otp_verified: bool,
}

#[derive(Serialize, Deserialize)]
pub struct DisableOtpResponse {
    pub status: String,
    pub otp_enabled: bool,
}

pub fn user_to_response(user: &User) -> UserData {
    UserData {
        id: user.id,
        username: user.username.to_owned(),
        otp_auth_url: user.otp_auth_url.to_owned(),
        otp_base32: user.otp_base32.to_owned(),
        otp_enabled: user.otp_enabled,
        otp_verified: user.otp_verified,
        createdAt: user.created_at,
        updatedAt: user.updated_at,
    }
}
