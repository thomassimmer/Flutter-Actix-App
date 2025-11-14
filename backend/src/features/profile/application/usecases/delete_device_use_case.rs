use uuid::Uuid;

use crate::features::profile::application::dto::DeviceDeleteResponse;
use crate::features::profile::domain::errors::ProfileDomainError;
use crate::features::profile::domain::repositories::DeviceRepository;

pub struct DeleteDeviceUseCase {
    device_repository: Box<dyn DeviceRepository>,
}

impl DeleteDeviceUseCase {
    pub fn new(device_repository: Box<dyn DeviceRepository>) -> Self {
        Self { device_repository }
    }

    pub async fn execute(&self, token_id: Uuid) -> Result<DeviceDeleteResponse, ProfileDomainError> {
        self.device_repository.delete_by_token_id(token_id).await?;

        Ok(DeviceDeleteResponse {
            code: "DEVICE_DELETED".to_string(),
        })
    }
}

