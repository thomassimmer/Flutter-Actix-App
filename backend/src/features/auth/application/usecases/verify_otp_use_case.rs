use totp_rs::{Algorithm, Secret, TOTP};
use uuid::Uuid;

use crate::features::auth::application::dto::VerifyOtpRequest;
use crate::features::auth::application::dto::VerifyOtpResponse;
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::UserRepository;

pub struct VerifyOtpUseCase {
    user_repository: Box<dyn UserRepository>,
}

impl VerifyOtpUseCase {
    pub fn new(user_repository: Box<dyn UserRepository>) -> Self {
        Self { user_repository }
    }

    pub async fn execute(
        &self,
        user_id: Uuid,
        request: VerifyOtpRequest,
    ) -> Result<VerifyOtpResponse, AuthDomainError> {
        let mut user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or(AuthDomainError::UserNotFound)?;

        let otp_base32 = user
            .otp_base32
            .as_ref()
            .ok_or(AuthDomainError::OtpNotEnabled)?;

        let totp = TOTP::new(
            Algorithm::SHA1,
            6,
            1,
            30,
            Secret::Encoded(otp_base32.clone()).to_bytes().unwrap(),
        )
        .map_err(|_| AuthDomainError::InvalidOtp)?;

        let is_valid = totp.check_current(&request.code).unwrap_or(false);

        if !is_valid {
            return Err(AuthDomainError::InvalidOtp);
        }

        user.otp_verified = true;
        self.user_repository.update(&user).await?;

        Ok(VerifyOtpResponse {
            code: "OTP_VERIFIED".to_string(),
            otp_verified: true,
        })
    }
}

