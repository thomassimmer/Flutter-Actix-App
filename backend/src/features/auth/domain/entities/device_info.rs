use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceInfo {
    pub os: Option<String>,
    pub is_mobile: Option<bool>,
    pub browser: Option<String>,
    pub app_version: Option<String>,
    pub model: Option<String>,
}

