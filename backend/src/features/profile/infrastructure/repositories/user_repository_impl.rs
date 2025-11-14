use uuid::Uuid;

use crate::features::profile::domain::entities::User;
use crate::features::profile::domain::errors::ProfileDomainError;
use crate::features::profile::domain::repositories::UserRepository;
use crate::features::profile::infrastructure::models::UserModel;

#[derive(Clone)]
pub struct UserRepositoryImpl {
    pool: sqlx::PgPool,
}

impl UserRepositoryImpl {
    pub fn new(pool: sqlx::PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait::async_trait]
impl UserRepository for UserRepositoryImpl {
    async fn find_by_id(&self, user_id: Uuid) -> Result<Option<User>, ProfileDomainError> {
        let user_model = sqlx::query_as!(
            UserModel,
            r#"
            SELECT id, username, password, locale, theme, otp_verified, otp_base32, otp_auth_url, password_is_expired, created_at, updated_at
            FROM users
            WHERE id = $1
            "#,
            user_id,
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            ProfileDomainError::UserNotFound
        })?;

        Ok(user_model.map(|u| u.into()))
    }

    async fn find_by_username(&self, username: &str) -> Result<Option<User>, ProfileDomainError> {
        let user_model = sqlx::query_as!(
            UserModel,
            r#"
            SELECT id, username, password, locale, theme, otp_verified, otp_base32, otp_auth_url, password_is_expired, created_at, updated_at
            FROM users
            WHERE username = $1
            "#,
            username
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            ProfileDomainError::UserNotFound
        })?;

        Ok(user_model.map(|u| u.into()))
    }

    async fn update(&self, user: &User) -> Result<(), ProfileDomainError> {
        let user_model: UserModel = user.clone().into();
        
        sqlx::query!(
            r#"
            UPDATE users
            SET 
                username = $1, password = $2, locale = $3, theme = $4,
                otp_verified = $5, otp_base32 = $6, otp_auth_url = $7,
                updated_at = $8, password_is_expired = $9
            WHERE id = $10
            "#,
            user_model.username,
            user_model.password,
            user_model.locale,
            user_model.theme,
            user_model.otp_verified,
            user_model.otp_base32,
            user_model.otp_auth_url,
            user_model.updated_at,
            user_model.password_is_expired,
            user_model.id,
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            ProfileDomainError::UserUpdateFailed
        })?;

        Ok(())
    }
}

