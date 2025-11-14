use argon2::{password_hash::SaltString, Argon2, PasswordHasher};
use rand::{distributions::Alphanumeric, rngs::OsRng, Rng};
use uuid::Uuid;

use crate::core::helpers::mock_now::now;
use crate::features::auth::application::dto::{SignupRequest, SignupResponse};
use crate::features::auth::domain::entities::{DeviceInfo, User};
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::{
    TokenRepository, TokenService, UserRepository,
};

pub struct SignupUseCase {
    user_repository: Box<dyn UserRepository>,
    token_repository: Box<dyn TokenRepository>,
    token_service: Box<dyn TokenService>,
    #[allow(dead_code)] // Stored for potential future use
    secret_key: Vec<u8>,
}

impl SignupUseCase {
    pub fn new(
        user_repository: Box<dyn UserRepository>,
        token_repository: Box<dyn TokenRepository>,
        token_service: Box<dyn TokenService>,
        secret_key: Vec<u8>,
    ) -> Self {
        Self {
            user_repository,
            token_repository,
            token_service,
            secret_key,
        }
    }

    pub async fn execute(
        &self,
        request: SignupRequest,
        device_info: DeviceInfo,
    ) -> Result<SignupResponse, AuthDomainError> {
        // Validate username and password
        let username_lower = request.username.to_lowercase();
        
        // Check if user already exists
        if (self.user_repository.find_by_username(&username_lower).await?).is_some() {
            return Err(AuthDomainError::UserAlreadyExists);
        }

        // Hash password
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        let password_hash = argon2
            .hash_password(request.password.as_bytes(), &salt)
            .map_err(|_| AuthDomainError::InvalidPassword)?
            .to_string();

        // Generate recovery codes
        let mut clear_recovery_codes = Vec::new();
        let mut hashed_recovery_codes = Vec::new();
        for _ in 0..5 {
            let code: String = rand::thread_rng()
                .sample_iter(&Alphanumeric)
                .take(16)
                .map(char::from)
                .collect();

            clear_recovery_codes.push(code.clone());

            let hashed_code = argon2
                .hash_password(code.as_bytes(), &salt)
                .map_err(|_| AuthDomainError::InvalidPassword)?
                .to_string();

            hashed_recovery_codes.push(hashed_code);
        }

        // Create user entity
        let user_id = Uuid::new_v4();
        let now_time = now();
        let user = User {
            id: user_id,
            username: username_lower,
            password_hash,
            locale: request.locale,
            theme: request.theme,
            is_admin: false,
            otp_verified: false,
            otp_base32: None,
            otp_auth_url: None,
            recovery_codes: hashed_recovery_codes.join(";"),
            password_is_expired: false,
            created_at: now_time,
            updated_at: now_time,
        };

        // Save user
        self.user_repository.create(&user).await?;

        // Generate tokens
        let jti = Uuid::new_v4();
        use crate::features::auth::domain::entities::Claims;
        let claims = Claims {
            exp: now_time.checked_add_signed(chrono::Duration::minutes(15)).unwrap().timestamp(),
            jti,
            user_id,
            is_admin: false,
        };

        let access_token = self.token_service.generate_access_token(&claims)?;
        let refresh_claims = Claims {
            exp: now_time.checked_add_signed(chrono::Duration::days(7)).unwrap().timestamp(),
            jti,
            user_id,
            is_admin: false,
        };
        let refresh_token = self.token_service.generate_refresh_token(&refresh_claims)?;

        // Save token
        use crate::features::auth::domain::entities::UserToken;
        let user_token = UserToken {
            id: Uuid::new_v4(),
            user_id,
            token_id: jti,
            expires_at: now_time.checked_add_signed(chrono::Duration::days(7)).unwrap(),
            os: device_info.os,
            is_mobile: device_info.is_mobile,
            browser: device_info.browser,
            app_version: device_info.app_version,
            model: device_info.model,
        };
        self.token_repository.save(&user_token).await?;

        Ok(SignupResponse {
            code: "USER_SIGNED_UP".to_string(),
            recovery_codes: clear_recovery_codes,
            access_token,
            refresh_token,
        })
    }
}

