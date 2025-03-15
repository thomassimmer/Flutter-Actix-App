use crate::schema::users;
use bb8::Pool;
use chrono::prelude::*;
use diesel::{
    prelude::{Insertable, Queryable},
    Selectable,
};
use diesel_async::{pooled_connection::AsyncDieselConnectionManager, AsyncPgConnection};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[allow(non_snake_case)]
#[derive(Debug, Deserialize, Serialize, Clone, Queryable, Selectable, Insertable)]
#[diesel(table_name = users)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub password: String,

    pub otp_enabled: bool,
    pub otp_verified: bool,
    pub otp_base32: Option<String>,
    pub otp_auth_url: Option<String>,

    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,

    pub recovery_codes: Vec<String>,
}
pub struct AppState {
    pub pool: Pool<AsyncDieselConnectionManager<AsyncPgConnection>>,
}

impl AppState {
    pub async fn init() -> AppState {
        let manager = AsyncDieselConnectionManager::<AsyncPgConnection>::new(
            std::env::var("DATABASE_URL").expect("DATABASE_URL must be set"),
        );

        let pool = Pool::builder()
            .max_size(15)
            .build(manager)
            .await
            .expect("Failed to create pool.");

        AppState { pool }
    }
}

#[derive(Debug, Deserialize)]
pub struct UserRegisterSchema {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct UserLoginSchema {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct GenerateOTPSchema {
    pub username: String,
    pub user_id: String,
}

#[derive(Debug, Deserialize)]
pub struct VerifyOTPSchema {
    pub user_id: Uuid,
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct DisableOTPSchema {
    pub user_id: Uuid,
}
