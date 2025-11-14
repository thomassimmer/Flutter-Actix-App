use crate::features::profile::application::dto::{IsOtpEnabledRequest, IsOtpEnabledResponse};
use crate::features::profile::domain::errors::ProfileDomainError;
use crate::features::profile::domain::repositories::UserRepository;

pub struct IsOtpEnabledUseCase {
    user_repository: Box<dyn UserRepository>,
}

impl IsOtpEnabledUseCase {
    pub fn new(user_repository: Box<dyn UserRepository>) -> Self {
        Self { user_repository }
    }

    pub async fn execute(
        &self,
        request: IsOtpEnabledRequest,
    ) -> Result<IsOtpEnabledResponse, ProfileDomainError> {
        let user = self
            .user_repository
            .find_by_username(&request.username)
            .await?;

        // If user does not exist, return false to avoid username enumeration
        let otp_enabled = user.map(|u| u.otp_verified).unwrap_or(false);

        Ok(IsOtpEnabledResponse {
            code: "OTP_STATUS".to_string(),
            otp_enabled,
        })
    }
}

