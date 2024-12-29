use sqlx::{Error, PgConnection};
use uuid::Uuid;

use crate::features::profile::structs::models::User;

pub async fn get_user(
    user_id: Uuid,
    transaction: &mut PgConnection,
) -> Result<Option<User>, Error> {
    sqlx::query_as!(
        User,
        r#"
        SELECT *
        FROM users
        WHERE id = $1
        "#,
        user_id,
    )
    .fetch_optional(&mut *transaction)
    .await
}
