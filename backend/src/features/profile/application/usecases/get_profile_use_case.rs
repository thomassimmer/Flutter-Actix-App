use uuid::Uuid;

use crate::features::profile::application::dto::{ProfileResponse, UserData};
use crate::features::profile::domain::errors::ProfileDomainError;
use crate::features::profile::domain::repositories::UserRepository;

pub struct GetProfileUseCase {
    user_repository: Box<dyn UserRepository>,
}

impl GetProfileUseCase {
    pub fn new(user_repository: Box<dyn UserRepository>) -> Self {
        Self { user_repository }
    }

    pub async fn execute(&self, user_id: Uuid) -> Result<ProfileResponse, ProfileDomainError> {
        let user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or(ProfileDomainError::UserNotFound)?;

        Ok(ProfileResponse {
            code: "PROFILE_FETCHED".to_string(),
            user: UserData {
                id: user.id,
                username: user.username,
                locale: user.locale,
                theme: user.theme,
                otp_verified: user.otp_verified,
                otp_base32: user.otp_base32,
                otp_auth_url: user.otp_auth_url,
                created_at: user.created_at,
                updated_at: user.updated_at,
                password_is_expired: user.password_is_expired,
            },
        })
    }
}

