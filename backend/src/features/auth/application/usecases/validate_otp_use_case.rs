use crate::core::helpers::mock_now::now;
use crate::features::auth::application::dto::{LoginResponse, ValidateOtpRequest};
use crate::features::auth::domain::entities::{Claims, DeviceInfo, UserToken};
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::{
    TokenRepository, TokenService, UserRepository,
};
use totp_rs::{Algorithm, Secret, TOTP};

pub struct ValidateOtpUseCase {
    user_repository: Box<dyn UserRepository>,
    token_repository: Box<dyn TokenRepository>,
    token_service: Box<dyn TokenService>,
}

impl ValidateOtpUseCase {
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
        request: ValidateOtpRequest,
        device_info: DeviceInfo,
    ) -> Result<LoginResponse, AuthDomainError> {
        let user = self
            .user_repository
            .find_by_id(request.user_id)
            .await?
            .ok_or(AuthDomainError::UserNotFound)?;

        if !user.otp_verified {
            return Err(AuthDomainError::OtpNotEnabled);
        }

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

        Ok(LoginResponse {
            code: "USER_LOGGED_IN_AFTER_OTP_VALIDATION".to_string(),
            access_token,
            refresh_token,
        })
    }
}

