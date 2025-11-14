use argon2::{password_hash::SaltString, Argon2, PasswordHasher};
use rand::rngs::OsRng;
use uuid::Uuid;

use crate::core::helpers::mock_now::now;
use crate::features::auth::helpers::password::{
    password_is_long_enough, password_is_strong_enough,
};
use crate::features::profile::application::dto::{ProfileResponse, SetPasswordRequest, UserData};
use crate::features::profile::domain::errors::ProfileDomainError;
use crate::features::profile::domain::repositories::UserRepository;

pub struct SetPasswordUseCase {
    user_repository: Box<dyn UserRepository>,
}

impl SetPasswordUseCase {
    pub fn new(user_repository: Box<dyn UserRepository>) -> Self {
        Self { user_repository }
    }

    pub async fn execute(
        &self,
        user_id: Uuid,
        request: SetPasswordRequest,
    ) -> Result<ProfileResponse, ProfileDomainError> {
        let mut user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or(ProfileDomainError::UserNotFound)?;

        if !user.password_is_expired {
            return Err(ProfileDomainError::PasswordNotExpired);
        }

        if !password_is_long_enough(&request.new_password) {
            return Err(ProfileDomainError::InvalidPassword);
        }

        if !password_is_strong_enough(&request.new_password) {
            return Err(ProfileDomainError::InvalidPassword);
        }

        // Hash the new password
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
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

