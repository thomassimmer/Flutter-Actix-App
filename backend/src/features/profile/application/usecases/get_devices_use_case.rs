use uuid::Uuid;

use crate::features::profile::application::dto::{DeviceData, DeviceInfo, DevicesResponse};
use crate::features::profile::domain::errors::ProfileDomainError;
use crate::features::profile::domain::repositories::DeviceRepository;

pub struct GetDevicesUseCase {
    device_repository: Box<dyn DeviceRepository>,
    token_cache: crate::features::auth::structs::models::TokenCache,
}

impl GetDevicesUseCase {
    pub fn new(
        device_repository: Box<dyn DeviceRepository>,
        token_cache: crate::features::auth::structs::models::TokenCache,
    ) -> Self {
        Self {
            device_repository,
            token_cache,
        }
    }

    pub async fn execute(&self, user_id: Uuid) -> Result<DevicesResponse, ProfileDomainError> {
        let devices = self.device_repository.find_all_by_user_id(user_id).await?;

        let mut device_data = Vec::new();
        for device in devices {
            let last_activity = self
                .token_cache
                .get_value_for_key(device.token_id)
                .await;

            device_data.push(DeviceData {
                token_id: device.token_id,
                parsed_device_info: DeviceInfo {
                    os: device.os,
                    is_mobile: device.is_mobile,
                    browser: device.browser,
                    app_version: device.app_version,
                    model: device.model,
                },
                last_activity_date: last_activity,
            });
        }

        Ok(DevicesResponse {
            code: "DEVICES_FETCHED".to_string(),
            devices: device_data,
        })
    }
}

