use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct UserUpdateRequest {
    pub username: String,
    pub locale: String,
    pub theme: String,
}