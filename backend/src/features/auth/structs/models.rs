use actix_http::Payload;
use actix_web::{FromRequest, HttpMessage, HttpRequest};
use futures_util::future::{err, ok, Ready};
use serde::{Deserialize, Serialize};
use sqlx::prelude::FromRow;
use uuid::Uuid;

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, FromRow)]
pub struct UserToken {
    pub id: Uuid,
    pub user_id: uuid::Uuid,
    pub token_id: String,
    pub expires_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub exp: u64,
    pub jti: String,
}

impl FromRequest for Claims {
    type Error = actix_web::Error;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _: &mut Payload) -> Self::Future {
        match req.extensions().get::<Claims>() {
            Some(claims) => return ok(claims.clone()),
            None => return err(actix_web::error::ErrorBadRequest("ups...")),
        };
    }
}
