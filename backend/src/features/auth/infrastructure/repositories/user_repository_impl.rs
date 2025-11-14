use uuid::Uuid;

use crate::features::auth::domain::entities::User;
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::UserRepository;
use crate::features::auth::infrastructure::models::UserModel;
// Unused imports removed

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
    async fn create(&self, user: &User) -> Result<(), AuthDomainError> {
        let user_model: UserModel = user.clone().into();
        
        sqlx::query!(
            r#"
            INSERT INTO users (
                id, username, password, locale, theme, otp_verified, otp_base32, otp_auth_url,
                created_at, updated_at, recovery_codes, password_is_expired, is_admin
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
            "#,
            user_model.id,
            user_model.username,
            user_model.password,
            user_model.locale,
            user_model.theme,
            user_model.otp_verified,
            user_model.otp_base32,
            user_model.otp_auth_url,
            user_model.created_at,
            user_model.updated_at,
            user_model.recovery_codes,
            user_model.password_is_expired,
            user_model.is_admin,
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            AuthDomainError::UserNotFound
        })?;

        Ok(())
    }

    async fn find_by_id(&self, user_id: Uuid) -> Result<Option<User>, AuthDomainError> {
        let user_model = sqlx::query_as!(
            UserModel,
            r#"
            SELECT *
            FROM users
            WHERE id = $1
            "#,
            user_id,
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            AuthDomainError::UserNotFound
        })?;

        Ok(user_model.map(|u| u.into()))
    }

    async fn find_by_username(&self, username: &str) -> Result<Option<User>, AuthDomainError> {
        let user_model = sqlx::query_as!(
            UserModel,
            r#"
            SELECT *
            FROM users
            WHERE username = $1
            "#,
            username
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            AuthDomainError::UserNotFound
        })?;

        Ok(user_model.map(|u| u.into()))
    }

    async fn update(&self, user: &User) -> Result<(), AuthDomainError> {
        let user_model: UserModel = user.clone().into();
        
        sqlx::query!(
            r#"
            UPDATE users
            SET 
                username = $1, password = $2, locale = $3, theme = $4,
                otp_verified = $5, otp_base32 = $6, otp_auth_url = $7,
                updated_at = $8, recovery_codes = $9, password_is_expired = $10, is_admin = $11
            WHERE id = $12
            "#,
            user_model.username,
            user_model.password,
            user_model.locale,
            user_model.theme,
            user_model.otp_verified,
            user_model.otp_base32,
            user_model.otp_auth_url,
            user_model.updated_at,
            user_model.recovery_codes,
            user_model.password_is_expired,
            user_model.is_admin,
            user_model.id,
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            AuthDomainError::UserNotFound
        })?;

        Ok(())
    }
}

