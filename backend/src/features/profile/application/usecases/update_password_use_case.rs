use argon2::{password_hash::SaltString, Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use rand::rngs::OsRng;
use uuid::Uuid;

use crate::core::helpers::mock_now::now;
use crate::features::auth::helpers::password::{
    password_is_long_enough, password_is_strong_enough,
};
use crate::features::profile::application::dto::{ProfileResponse, UpdatePasswordRequest, UserData};
use crate::features::profile::domain::errors::ProfileDomainError;
use crate::features::profile::domain::repositories::UserRepository;

pub struct UpdatePasswordUseCase {
    user_repository: Box<dyn UserRepository>,
}

impl UpdatePasswordUseCase {
    pub fn new(user_repository: Box<dyn UserRepository>) -> Self {
        Self { user_repository }
    }

    pub async fn execute(
        &self,
        user_id: Uuid,
        request: UpdatePasswordRequest,
    ) -> Result<ProfileResponse, ProfileDomainError> {
        let mut user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or(ProfileDomainError::UserNotFound)?;

        // Verify current password
        let parsed_hash = PasswordHash::new(&user.password_hash)
            .map_err(|_| ProfileDomainError::InvalidPassword)?;
        let argon2 = Argon2::default();
        let is_valid = argon2
            .verify_password(request.current_password.as_bytes(), &parsed_hash)
            .is_ok();

        if !is_valid {
            return Err(ProfileDomainError::InvalidPassword);
        }

        // Validate new password
        if !password_is_long_enough(&request.new_password) {
            return Err(ProfileDomainError::InvalidPassword);
        }

        if !password_is_strong_enough(&request.new_password) {
            return Err(ProfileDomainError::InvalidPassword);
        }

        // Hash the new password
        let salt = SaltString::generate(&mut OsRng);
        let password_hash = argon2
            .hash_password(request.new_password.as_bytes(), &salt)
            .map_err(|_| ProfileDomainError::PasswordUpdateFailed)?
            .to_string();

        user.password_hash = password_hash;
        user.password_is_expired = false;
        user.updated_at = now();

        self.user_repository.update(&user).await?;

        Ok(ProfileResponse {
            code: "PASSWORD_CHANGED".to_string(),
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

