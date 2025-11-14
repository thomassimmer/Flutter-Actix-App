use uuid::Uuid;

use crate::features::auth::domain::entities::{Claims, UserToken};
use crate::features::auth::domain::errors::AuthDomainError;

#[async_trait::async_trait]
pub trait TokenRepository: Send + Sync {
    async fn save(&self, token: &UserToken) -> Result<(), AuthDomainError>;
    async fn find_by_user_id_and_token_id(
        &self,
        user_id: Uuid,
        token_id: Uuid,
    ) -> Result<Option<UserToken>, AuthDomainError>;
    async fn find_all_by_user_id(&self, user_id: Uuid) -> Result<Vec<UserToken>, AuthDomainError>;
    async fn delete_by_token_id(&self, token_id: Uuid) -> Result<(), AuthDomainError>;
    async fn delete_all_by_user_id(&self, user_id: Uuid) -> Result<(), AuthDomainError>;
}

#[async_trait::async_trait]
pub trait TokenService: Send + Sync {
    fn generate_access_token(&self, claims: &Claims) -> Result<String, AuthDomainError>;
    fn generate_refresh_token(&self, claims: &Claims) -> Result<String, AuthDomainError>;
    fn decode_token(&self, token: &str) -> Result<Claims, AuthDomainError>;
    fn hash_token(&self, token: &str) -> String;
}

