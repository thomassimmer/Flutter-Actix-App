use uuid::Uuid;

use crate::features::profile::domain::entities::Device;
use crate::features::profile::domain::errors::ProfileDomainError;
use crate::features::profile::domain::repositories::DeviceRepository;
use crate::features::profile::infrastructure::models::DeviceModel;

#[derive(Clone)]
pub struct DeviceRepositoryImpl {
    pool: sqlx::PgPool,
}

impl DeviceRepositoryImpl {
    pub fn new(pool: sqlx::PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait::async_trait]
impl DeviceRepository for DeviceRepositoryImpl {
    async fn find_all_by_user_id(&self, user_id: Uuid) -> Result<Vec<Device>, ProfileDomainError> {
        let devices = sqlx::query_as!(
            DeviceModel,
            r#"
            SELECT id, user_id, token_id, expires_at, os, is_mobile, browser, app_version, model
            FROM user_tokens
            WHERE user_id = $1
            "#,
            user_id
        )
        .fetch_all(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            ProfileDomainError::DeviceNotFound
        })?;

        Ok(devices.into_iter().map(|d| d.into()).collect())
    }

    async fn delete_by_token_id(&self, token_id: Uuid) -> Result<(), ProfileDomainError> {
        sqlx::query!(
            r#"
            DELETE
            FROM user_tokens
            WHERE token_id = $1
            "#,
            token_id
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            ProfileDomainError::DeviceNotFound
        })?;

        Ok(())
    }
}

