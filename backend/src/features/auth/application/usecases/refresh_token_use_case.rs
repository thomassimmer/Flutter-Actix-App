use crate::core::helpers::mock_now::now;
use crate::features::auth::application::dto::refresh_token_response::RefreshTokenResponse;
use crate::features::auth::application::dto::RefreshTokenRequest;
use crate::features::auth::domain::entities::{Claims, DeviceInfo, UserToken};
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::{TokenRepository, TokenService};

pub struct RefreshTokenUseCase {
    token_repository: Box<dyn TokenRepository>,
    token_service: Box<dyn TokenService>,
}

impl RefreshTokenUseCase {
    pub fn new(
        token_repository: Box<dyn TokenRepository>,
        token_service: Box<dyn TokenService>,
    ) -> Self {
        Self {
            token_repository,
            token_service,
        }
    }

    pub async fn execute(
        &self,
        request: RefreshTokenRequest,
        device_info: DeviceInfo,
    ) -> Result<RefreshTokenResponse, AuthDomainError> {
        // Decode refresh token
        let claims = self.token_service.decode_token(&request.refresh_token)?;

        // Check if token exists in database
        let stored_token = self
            .token_repository
            .find_by_user_id_and_token_id(claims.user_id, claims.jti)
            .await?;

        let token = stored_token.ok_or(AuthDomainError::InvalidToken)?;

        // Check if token expired
        if now() > token.expires_at {
            // Remove expired token
            let _ = self.token_repository.delete_by_token_id(claims.jti).await;
            return Err(AuthDomainError::TokenExpired);
        }

        // Delete old token
        self.token_repository.delete_by_token_id(claims.jti).await?;

        // Generate new tokens
        let new_jti = uuid::Uuid::new_v4();
        let now_time = now();
        let access_claims = Claims {
            exp: now_time
                .checked_add_signed(chrono::Duration::minutes(15))
                .unwrap()
                .timestamp(),
            jti: new_jti,
            user_id: claims.user_id,
            is_admin: claims.is_admin,
        };

        let access_token = self.token_service.generate_access_token(&access_claims)?;

        let refresh_claims = Claims {
            exp: now_time
                .checked_add_signed(chrono::Duration::days(7))
                .unwrap()
                .timestamp(),
            jti: new_jti,
            user_id: claims.user_id,
            is_admin: claims.is_admin,
        };
        let refresh_token = self.token_service.generate_refresh_token(&refresh_claims)?;

        // Save new token
        let user_token = UserToken {
            id: uuid::Uuid::new_v4(),
            user_id: claims.user_id,
            token_id: new_jti,
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

        Ok(RefreshTokenResponse {
            code: "TOKEN_REFRESHED".to_string(),
            access_token,
            refresh_token,
        })
    }
}
