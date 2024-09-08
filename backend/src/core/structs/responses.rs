use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct GenericResponse {
    pub code: String,
    pub message: String,
}
