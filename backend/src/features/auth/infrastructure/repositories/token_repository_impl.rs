use uuid::Uuid;

use crate::features::auth::domain::entities::{Claims, UserToken};
use crate::features::auth::domain::errors::AuthDomainError;
use crate::features::auth::domain::repositories::{TokenRepository, TokenService};
use crate::features::auth::infrastructure::models::UserTokenModel;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use sha2::{Digest, Sha256};

#[derive(Clone)]
pub struct TokenRepositoryImpl {
    pool: sqlx::PgPool,
}

impl TokenRepositoryImpl {
    pub fn new(pool: sqlx::PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait::async_trait]
impl TokenRepository for TokenRepositoryImpl {
    async fn save(&self, token: &UserToken) -> Result<(), AuthDomainError> {
        let token_model: UserTokenModel = token.clone().into();
        
        sqlx::query!(
            r#"
            INSERT INTO user_tokens (id, user_id, token_id, expires_at, os, is_mobile, browser, app_version, model)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            "#,
            token_model.id,
            token_model.user_id,
            token_model.token_id,
            token_model.expires_at,
            token_model.os,
            token_model.is_mobile,
            token_model.browser,
            token_model.app_version,
            token_model.model
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            AuthDomainError::InvalidToken
        })?;

        Ok(())
    }

    async fn find_by_user_id_and_token_id(
        &self,
        user_id: Uuid,
        token_id: Uuid,
    ) -> Result<Option<UserToken>, AuthDomainError> {
        let token_model = sqlx::query_as!(
            UserTokenModel,
            r#"
            SELECT *
            FROM user_tokens
            WHERE user_id = $1 and token_id = $2
            "#,
            user_id,
            token_id,
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            AuthDomainError::InvalidToken
        })?;

        Ok(token_model.map(|t| t.into()))
    }

    async fn find_all_by_user_id(&self, user_id: Uuid) -> Result<Vec<UserToken>, AuthDomainError> {
        let tokens = sqlx::query_as!(
            UserTokenModel,
            r#"
            SELECT *
            FROM user_tokens
            WHERE user_id = $1
            "#,
            user_id
        )
        .fetch_all(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            AuthDomainError::InvalidToken
        })?;

        Ok(tokens.into_iter().map(|t| t.into()).collect())
    }

    async fn delete_by_token_id(&self, token_id: Uuid) -> Result<(), AuthDomainError> {
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
            AuthDomainError::InvalidToken
        })?;

        Ok(())
    }

    async fn delete_all_by_user_id(&self, user_id: Uuid) -> Result<(), AuthDomainError> {
        sqlx::query!(
            r#"
            DELETE
            FROM user_tokens
            WHERE user_id = $1
            "#,
            user_id
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            AuthDomainError::InvalidToken
        })?;

        Ok(())
    }
}

#[derive(Clone)]
pub struct TokenServiceImpl {
    secret_key: Vec<u8>,
}

impl TokenServiceImpl {
    pub fn new(secret_key: Vec<u8>) -> Self {
        Self { secret_key }
    }
}

impl TokenService for TokenServiceImpl {
    fn generate_access_token(&self, claims: &Claims) -> Result<String, AuthDomainError> {
        encode(
            &Header::default(),
            claims,
            &EncodingKey::from_secret(&self.secret_key),
        )
        .map_err(|_| AuthDomainError::InvalidToken)
    }

    fn generate_refresh_token(&self, claims: &Claims) -> Result<String, AuthDomainError> {
        encode(
            &Header::default(),
            claims,
            &EncodingKey::from_secret(&self.secret_key),
        )
        .map_err(|_| AuthDomainError::InvalidToken)
    }

    fn decode_token(&self, token: &str) -> Result<Claims, AuthDomainError> {
        let decoding_key = DecodingKey::from_secret(&self.secret_key);
        let token_data = decode::<Claims>(token, &decoding_key, &Validation::default())
            .map_err(|_| AuthDomainError::InvalidToken)?;

        Ok(token_data.claims)
    }

    fn hash_token(&self, token: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(token);
        format!("{:X}", hasher.finalize())
    }
}

