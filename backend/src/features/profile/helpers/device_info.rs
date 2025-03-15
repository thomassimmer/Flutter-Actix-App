use actix_web::HttpRequest;

use crate::features::profile::structs::models::ParsedDeviceInfo;

pub async fn get_user_agent(req: HttpRequest) -> ParsedDeviceInfo {
    if let Some(user_agent) = req.headers().get("X-User-Agent") {
        let user_agent = user_agent.to_str().unwrap_or("");

        if let Ok(parsed_device_info) = ParsedDeviceInfo::from_user_agent(user_agent) {
            return parsed_device_info;
        }
    }

    ParsedDeviceInfo {
        os: None,
        is_mobile: None,
        browser: None,
        app_version: None,
        model: None,
    }
}
