use actix_http::Payload;
use actix_web::{FromRequest, HttpMessage, HttpRequest};
use chrono::{DateTime, Utc};
use futures_util::future::{err, ok, Ready};
use serde::{Deserialize, Serialize};
use sqlx::prelude::FromRow;
use uuid::Uuid;

#[allow(non_snake_case)]
#[derive(Serialize, Debug, Deserialize)]
pub struct UserData {
    pub id: Uuid,
    pub username: String,
    pub locale: String,
    pub theme: String,

    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub createdAt: DateTime<Utc>,
    pub updatedAt: DateTime<Utc>,

    pub password_is_expired: bool,
}

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, FromRow)]
pub struct User {
    pub id: uuid::Uuid,
    pub username: String, // lowercase
    pub password: String, // case sensitive
    pub locale: String,
    pub theme: String,

    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,

    pub recovery_codes: String, // case sensitive
    pub password_is_expired: bool,
}

impl User {
    pub fn to_user_data(&self) -> UserData {
        UserData {
            id: self.id,
            username: self.username.to_owned(),
            locale: self.locale.to_owned(),
            theme: self.theme.to_owned(),
            otp_auth_url: self.otp_auth_url.to_owned(),
            otp_base32: self.otp_base32.to_owned(),
            otp_verified: self.otp_verified,
            createdAt: self.created_at,
            updatedAt: self.updated_at,
            password_is_expired: self.password_is_expired,
        }
    }
}

impl FromRequest for User {
    type Error = actix_web::Error;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _: &mut Payload) -> Self::Future {
        match req.extensions().get::<User>() {
            Some(user) => ok(user.clone()),
            None => err(actix_web::error::ErrorBadRequest("ups...")),
        }
    }
}
