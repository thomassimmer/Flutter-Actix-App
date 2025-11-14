use actix_web::{delete, get, web, web::Path, web::ReqData, HttpResponse, Responder};
use tracing::error;
use uuid::Uuid;

use crate::core::structs::responses::GenericResponse;
use crate::features::auth::domain::entities::Claims;
use crate::features::profile::application::usecases::{DeleteDeviceUseCase, GetDevicesUseCase};

#[get("/")]
pub async fn get_devices(
    claims: ReqData<Claims>,
    use_case: web::Data<GetDevicesUseCase>,
) -> impl Responder {
    match use_case.execute(claims.user_id).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Get devices error: {}", e);
            HttpResponse::InternalServerError().json(GenericResponse {
                code: "DEVICES_FETCH_ERROR".to_string(),
                message: "Failed to fetch devices".to_string(),
            })
        }
    }
}

#[delete("/{token_id}")]
pub async fn delete_device(
    _claims: ReqData<Claims>,
    token_id: Path<Uuid>,
    use_case: web::Data<DeleteDeviceUseCase>,
) -> impl Responder {
    match use_case.execute(*token_id).await {
        Ok(response) => HttpResponse::Ok().json(response),
        Err(e) => {
            error!("Delete device error: {}", e);
            HttpResponse::InternalServerError().json(GenericResponse {
                code: "DEVICE_DELETE_ERROR".to_string(),
                message: "Failed to delete device".to_string(),
            })
        }
    }
}

