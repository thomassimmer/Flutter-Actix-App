use std::{collections::HashMap, sync::Arc};

use chrono::{DateTime, Utc};
use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Default, Clone)]
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
