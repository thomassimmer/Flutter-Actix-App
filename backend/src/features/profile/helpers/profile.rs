use sqlx::{postgres::PgQueryResult, Error, Executor, Postgres};
use uuid::Uuid;

use crate::features::profile::structs::models::User;

pub async fn get_user_by_id<'a, E>(executor: E, user_id: Uuid) -> Result<Option<User>, Error>
where
    E: Executor<'a, Database = Postgres>,
{
    sqlx::query_as!(
        User,
        r#"
        SELECT *
        FROM users
        WHERE id = $1
        "#,
        user_id,
    )
    .fetch_optional(executor)
    .await
}

pub async fn create_user<'a, E>(executor: E, user: &User) -> Result<PgQueryResult, sqlx::Error>
where
    E: Executor<'a, Database = Postgres>,
{
    sqlx::query!(
        r#"
        INSERT INTO users (
            id,
            username,
            password,
            otp_verified,
            otp_base32,
            otp_auth_url,
            created_at,
            updated_at,
            recovery_codes,
            password_is_expired,
            is_admin
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        "#,
        user.id,
        user.username,
        user.password,
        user.otp_verified,
        user.otp_base32,
        user.otp_auth_url,
        user.created_at,
        user.updated_at,
        user.recovery_codes,
        user.password_is_expired,
        user.is_admin,
    )
    .execute(executor)
    .await
}

pub async fn update_user<'a, E>(executor: E, user: &User) -> Result<PgQueryResult, sqlx::Error>
where
    E: Executor<'a, Database = Postgres>,
{
    sqlx::query!(
        r#"
        UPDATE users
        SET 
            username = $1,
            password = $2,
            otp_verified = $3,
            otp_base32 = $4,
            otp_auth_url = $5,
            created_at = $6,
            updated_at = $7,
            recovery_codes = $8,
            password_is_expired = $9,
            is_admin = $10
        WHERE id = $11
        "#,
        user.username,
        user.password,
        user.otp_verified,
        user.otp_base32,
        user.otp_auth_url,
        user.created_at,
        user.updated_at,
        user.recovery_codes,
        user.password_is_expired,
        user.is_admin,
        user.id,
    )
    .execute(executor)
    .await
}

pub async fn get_user_by_username<'a, E>(
    executor: E,
    username: &str,
) -> Result<Option<User>, sqlx::Error>
where
    E: Executor<'a, Database = Postgres>,
{
    let user = sqlx::query_as!(User, "SELECT * FROM users WHERE username = $1", username)
        .fetch_optional(executor)
        .await?;

    Ok(user)
}
