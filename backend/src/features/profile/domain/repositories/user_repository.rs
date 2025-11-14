use uuid::Uuid;

use crate::features::profile::domain::entities::User;
use crate::features::profile::domain::errors::ProfileDomainError;

#[async_trait::async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, user_id: Uuid) -> Result<Option<User>, ProfileDomainError>;
    async fn find_by_username(&self, username: &str) -> Result<Option<User>, ProfileDomainError>;
    async fn update(&self, user: &User) -> Result<(), ProfileDomainError>;
}

