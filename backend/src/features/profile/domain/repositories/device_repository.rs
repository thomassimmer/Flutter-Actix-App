use uuid::Uuid;

use crate::features::profile::domain::entities::Device;
use crate::features::profile::domain::errors::ProfileDomainError;

#[async_trait::async_trait]
pub trait DeviceRepository: Send + Sync {
    async fn find_all_by_user_id(&self, user_id: Uuid) -> Result<Vec<Device>, ProfileDomainError>;
    async fn delete_by_token_id(&self, token_id: Uuid) -> Result<(), ProfileDomainError>;
}

