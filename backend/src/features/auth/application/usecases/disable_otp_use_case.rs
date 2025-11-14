use uuid::Uuid;

use crate::features::auth::application::dto::DisableOtpResponse;
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::UserRepository;

pub struct DisableOtpUseCase {
    user_repository: Box<dyn UserRepository>,
}

impl DisableOtpUseCase {
    pub fn new(user_repository: Box<dyn UserRepository>) -> Self {
        Self { user_repository }
    }

    pub async fn execute(&self, user_id: Uuid) -> Result<DisableOtpResponse, AuthDomainError> {
        let mut user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or(AuthDomainError::UserNotFound)?;

        user.otp_verified = false;
        user.otp_base32 = None;
        user.otp_auth_url = None;

        self.user_repository.update(&user).await?;

        Ok(DisableOtpResponse {
            code: "OTP_DISABLED".to_string(),
            two_fa_enabled: false,
        })
    }
}
