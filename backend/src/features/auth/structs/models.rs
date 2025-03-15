use std::{collections::HashMap, sync::Arc};

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::prelude::FromRow;
use tokio::sync::RwLock;
use uuid::Uuid;

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, FromRow)]
pub struct UserToken {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token_id: Uuid,
    pub expires_at: chrono::DateTime<chrono::Utc>,
    pub os: Option<String>,
    pub is_mobile: Option<bool>,
    pub browser: Option<String>,
    pub app_version: Option<String>,
    pub model: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub exp: i64,
    pub jti: Uuid,
    pub user_id: Uuid,
    pub is_admin: bool,
}

#[derive(Default)]
pub struct TokenCache {
    data: Arc<RwLock<HashMap<Uuid, DateTime<Utc>>>>,
}

impl TokenCache {
    pub async fn update_or_insert_key(&self, key: Uuid, value: DateTime<Utc>) {
        self.data
            .write()
            .await
            .entry(key)
            .and_modify(|v| *v = value)
            .or_insert(value);
    }

    pub async fn remove_key(&self, key: Uuid) {
        self.data.write().await.remove(&key);
    }

    pub async fn get_value_for_key(&self, key: Uuid) -> Option<DateTime<Utc>> {
        self.data.read().await.get(&key).cloned()
    }
}
