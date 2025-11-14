use uuid::Uuid;

use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::TokenRepository;
use crate::features::auth::structs::models::TokenCache;

pub struct LogoutUseCase {
    token_repository: Box<dyn TokenRepository>,
    token_cache: TokenCache,
}

impl LogoutUseCase {
    pub fn new(token_repository: Box<dyn TokenRepository>, token_cache: TokenCache) -> Self {
        Self {
            token_repository,
            token_cache,
        }
    }

    pub async fn execute(&self, token_id: Uuid) -> Result<(), AuthDomainError> {
        // Delete from database
        self.token_repository.delete_by_token_id(token_id).await?;
        // Remove from cache
        self.token_cache.remove_key(token_id).await;
        Ok(())
    }
}

