use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::prelude::FromRow;
use uuid::Uuid;

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, FromRow)]
pub struct DeviceModel {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token_id: Uuid,
    pub expires_at: DateTime<Utc>,
    pub os: Option<String>,
    pub is_mobile: Option<bool>,
    pub browser: Option<String>,
    pub app_version: Option<String>,
    pub model: Option<String>,
}

impl From<DeviceModel> for crate::features::profile::domain::entities::Device {
    fn from(model: DeviceModel) -> Self {
        Self {
            token_id: model.token_id,
            user_id: model.user_id,
            os: model.os,
            is_mobile: model.is_mobile,
            browser: model.browser,
            app_version: model.app_version,
            model: model.model,
            expires_at: model.expires_at,
            last_activity: None, // This would need to come from TokenCache separately
        }
    }
}

impl From<crate::features::profile::domain::entities::Device> for DeviceModel {
    fn from(entity: crate::features::profile::domain::entities::Device) -> Self {
        Self {
            id: uuid::Uuid::new_v4(),
            user_id: entity.user_id,
            token_id: entity.token_id,
            expires_at: entity.expires_at,
            os: entity.os,
            is_mobile: entity.is_mobile,
            browser: entity.browser,
            app_version: entity.app_version,
            model: entity.model,
        }
    }
}

