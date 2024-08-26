use serde::{Deserialize, Serialize};

use super::model::UserData;

#[derive(Serialize, Deserialize)]
pub struct UserResponse {
    pub status: String,
    pub user: UserData,
}
