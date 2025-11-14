use argon2::{Argon2, PasswordHash, PasswordVerifier};
use totp_rs::{Algorithm, Secret, TOTP};

use crate::core::helpers::mock_now::now;
use crate::features::auth::application::dto::{LoginResponse, RecoverAccountUsing2FARequest};
use crate::features::auth::domain::entities::{Claims, DeviceInfo, UserToken};
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::{TokenRepository, TokenService, UserRepository};

pub struct RecoverAccountUsing2FAUseCase {
    user_repository: Box<dyn UserRepository>,
    token_repository: Box<dyn TokenRepository>,
    token_service: Box<dyn TokenService>,
}

impl RecoverAccountUsing2FAUseCase {
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
        request: RecoverAccountUsing2FARequest,
        device_info: DeviceInfo,
    ) -> Result<LoginResponse, AuthDomainError> {
        let username_lower = request.username.to_lowercase();

        let mut user = self
            .user_repository
            .find_by_username(&username_lower)
            .await?
            .ok_or(AuthDomainError::InvalidUsernameOrCodeOrRecoveryCode)?;

        // 2FA should be enabled
        if !user.otp_verified {
            return Err(AuthDomainError::TwoFactorAuthenticationNotEnabled);
        }

        // Verify OTP code
        let otp_base32 = user
            .otp_base32
            .as_ref()
            .ok_or(AuthDomainError::TwoFactorAuthenticationNotEnabled)?;

        let totp = TOTP::new(
            Algorithm::SHA1,
            6,
            1,
            30,
            Secret::Encoded(otp_base32.clone())
                .to_bytes()
                .map_err(|_| AuthDomainError::InvalidOtp)?,
        )
        .map_err(|_| AuthDomainError::InvalidOtp)?;

        let is_otp_valid = totp.check_current(&request.code).unwrap_or(false);

        if !is_otp_valid {
            return Err(AuthDomainError::InvalidUsernameOrCodeOrRecoveryCode);
        }

        // Verify recovery code
        let mut recovery_code_valid = false;
        let mut updated_recovery_codes = Vec::<String>::new();

        for recovery_code_hash in user.recovery_codes.split(";") {
            if recovery_code_hash.is_empty() {
                continue;
            }

            let parsed_hash = PasswordHash::new(recovery_code_hash)
                .map_err(|_| AuthDomainError::InvalidUsernameOrCodeOrRecoveryCode)?;
            let argon2 = Argon2::default();
            let is_valid = argon2
                .verify_password(request.recovery_code.as_bytes(), &parsed_hash)
                .is_ok();

            if is_valid {
                recovery_code_valid = true;
                // Don't add this recovery code to the updated list
                continue;
            } else {
                updated_recovery_codes.push(recovery_code_hash.to_string());
            }
        }

        if !recovery_code_valid {
            return Err(AuthDomainError::InvalidUsernameOrCodeOrRecoveryCode);
        }

        // Update recovery codes (remove the used one)
        user.recovery_codes = updated_recovery_codes.join(";");

        // Delete all existing tokens for this user
        self.token_repository
            .delete_all_by_user_id(user.id)
            .await?;

        // Generate new tokens
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

        // Save new token
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

        // Update user with new recovery codes
        self.user_repository.update(&user).await?;

        Ok(LoginResponse {
            code: "USER_LOGGED_IN_AFTER_ACCOUNT_RECOVERY".to_string(),
            access_token,
            refresh_token,
        })
    }
}

