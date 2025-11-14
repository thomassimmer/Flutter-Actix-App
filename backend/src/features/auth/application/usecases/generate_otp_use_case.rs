use base32;
use rand::Rng;
use totp_rs::{Algorithm, Secret, TOTP};
use uuid::Uuid;

use crate::features::auth::application::dto::GenerateOtpResponse;
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::UserRepository;

pub struct GenerateOtpUseCase {
    user_repository: Box<dyn UserRepository>,
}

impl GenerateOtpUseCase {
    pub fn new(user_repository: Box<dyn UserRepository>) -> Self {
        Self { user_repository }
    }

    pub async fn execute(&self, user_id: Uuid) -> Result<GenerateOtpResponse, AuthDomainError> {
        let mut user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or(AuthDomainError::UserNotFound)?;

        let mut rng = rand::thread_rng();
        let data_byte: [u8; 21] = rng.gen();
        let base32_string = base32::encode(base32::Alphabet::Rfc4648 { padding: false }, &data_byte);

        let totp = TOTP::new(
            Algorithm::SHA1,
            6,
            1,
            30,
            Secret::Encoded(base32_string).to_bytes().unwrap(),
        )
        .map_err(|_| AuthDomainError::InvalidOtp)?;

        let otp_base32 = totp.get_secret_base32();
        let username = user.username.clone();
        let issuer = "Flutter Actix App";

        let otp_auth_url =
            format!("otpauth://totp/{issuer}:{username}?secret={otp_base32}&issuer={issuer}");

        user.otp_base32 = Some(otp_base32.clone());
        user.otp_auth_url = Some(otp_auth_url.clone());
        user.otp_verified = false;

        self.user_repository.update(&user).await?;

        Ok(GenerateOtpResponse {
            code: "OTP_GENERATED".to_string(),
            otp_base32,
            otp_auth_url,
        })
    }
}

