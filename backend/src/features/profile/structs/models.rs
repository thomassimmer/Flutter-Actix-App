use std::collections::HashMap;

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ParsedDeviceInfo {
    pub os: Option<String>,
    pub is_mobile: Option<bool>,
    pub browser: Option<String>, // Name of the browser if not inside an app
    pub app_version: Option<String>,
    pub model: Option<String>, // Name of the device (ex: "Ravi's iPhone 13 Pro") or name the device's model (Ex: "MacBookPro18,3")
}

impl ParsedDeviceInfo {
    pub fn from_user_agent(user_agent: &str) -> Result<Self, String> {
        let mut fields = HashMap::new();

        for entry in user_agent.split("; ") {
            if let Some((key, value)) = entry.split_once('=') {
                fields.insert(key.trim(), value.trim());
            }
        }

        let parsed = ParsedDeviceInfo {
            os: fields.get("os").map(|s| s.to_string()),
            is_mobile: fields.get("isMobile").and_then(|s| s.parse::<bool>().ok()),
            browser: fields.get("browser").map(|s| s.to_string()),
            app_version: fields.get("appVersion").map(|s| s.to_string()),
            model: fields.get("model").map(|s| s.to_string()),
        };

        Ok(parsed)
    }
}
