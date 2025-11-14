use uuid::Uuid;

use crate::features::auth::domain::entities::User;
use crate::features::auth::domain::errors::AuthDomainError;

#[async_trait::async_trait]
pub trait UserRepository: Send + Sync {
    async fn create(&self, user: &User) -> Result<(), AuthDomainError>;
    async fn find_by_id(&self, user_id: Uuid) -> Result<Option<User>, AuthDomainError>;
    async fn find_by_username(&self, username: &str) -> Result<Option<User>, AuthDomainError>;
    async fn update(&self, user: &User) -> Result<(), AuthDomainError>;
}

