use argon2::{Argon2, PasswordHash, PasswordVerifier};

use crate::core::helpers::mock_now::now;
use crate::features::auth::application::dto::{LoginRequest, LoginResponse, LoginWhenOtpEnabledResponse};
use crate::features::auth::domain::entities::{Claims, DeviceInfo, UserToken};
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::{
    TokenRepository, TokenService, UserRepository,
};

pub struct LoginUseCase {
    user_repository: Box<dyn UserRepository>,
    token_repository: Box<dyn TokenRepository>,
    token_service: Box<dyn TokenService>,
}

impl LoginUseCase {
    pub fn new(
        user_repository: Box<dyn UserRepository>,
        token_repository: Box<dyn TokenRepository>,
        token_service: Box<dyn TokenService>,
    ) -> Self {
        Self {
            user_repository,
            token_repository,
            token_service,
        }
    }

    pub async fn execute(
        &self,
        request: LoginRequest,
        device_info: DeviceInfo,
    ) -> Result<Result<LoginResponse, LoginWhenOtpEnabledResponse>, AuthDomainError> {
        let username_lower = request.username.to_lowercase();

        let user = self
            .user_repository
            .find_by_username(&username_lower)
            .await?
            .ok_or(AuthDomainError::InvalidCredentials)?;

        // Verify password
        let parsed_hash = PasswordHash::new(&user.password_hash)
            .map_err(|_| AuthDomainError::InvalidCredentials)?;
        let argon2 = Argon2::default();
        let is_valid = argon2
            .verify_password(request.password.as_bytes(), &parsed_hash)
            .is_ok();

        if !is_valid {
            return Err(AuthDomainError::InvalidCredentials);
        }

        if user.password_is_expired {
            return Err(AuthDomainError::PasswordExpired);
        }

        if user.otp_verified {
            return Ok(Err(LoginWhenOtpEnabledResponse {
                code: "USER_LOGS_IN_WITH_OTP_ENABLED".to_string(),
                user_id: user.id.to_string(),
            }));
        }

        // Generate tokens
        let jti = uuid::Uuid::new_v4();
        let now_time = now();
        let access_claims = Claims {
            exp: now_time
                .checked_add_signed(chrono::Duration::minutes(15))
                .unwrap()
                .timestamp(),
            jti,
            user_id: user.id,
            is_admin: user.is_admin,
        };

        let access_token = self.token_service.generate_access_token(&access_claims)?;

        let refresh_claims = Claims {
            exp: now_time
                .checked_add_signed(chrono::Duration::days(7))
                .unwrap()
                .timestamp(),
            jti,
            user_id: user.id,
            is_admin: user.is_admin,
        };
        let refresh_token = self.token_service.generate_refresh_token(&refresh_claims)?;

        // Save token
        let user_token = UserToken {
            id: uuid::Uuid::new_v4(),
            user_id: user.id,
            token_id: jti,
            expires_at: now_time
                .checked_add_signed(chrono::Duration::days(7))
                .unwrap(),
            os: device_info.os,
            is_mobile: device_info.is_mobile,
            browser: device_info.browser,
            app_version: device_info.app_version,
            model: device_info.model,
        };
        self.token_repository.save(&user_token).await?;

        Ok(Ok(LoginResponse {
            code: "USER_LOGGED_IN_WITHOUT_OTP".to_string(),
            access_token,
            refresh_token,
        }))
    }
}

