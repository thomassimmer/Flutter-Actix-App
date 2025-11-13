use actix_http::Request;
use actix_web::body::MessageBody;
use actix_web::dev::{Service, ServiceResponse};
use actix_web::http::header::{self};
use actix_web::{test, Error};
use flutteractixapp::features::profile::structs::responses::{
    DeviceData, DeviceDeleteResponse, DevicesResponse,
};
use sqlx::PgPool;
use uuid::Uuid;

use crate::auth::login::user_logs_in;
use crate::auth::signup::user_signs_up;
use crate::helpers::spawn_app;

pub async fn user_gets_list_of_devices(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    access_token: &str,
) -> Vec<DeviceData> {
    let req = test::TestRequest::get()
        .uri("/api/devices/")
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: DevicesResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "DEVICES_FETCHED");
    response.devices
}

pub async fn user_removes_a_device(
    app: impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error>,
    access_token: &str,
    device_id: Uuid,
) {
    let req = test::TestRequest::delete()
        .uri(&format!("/api/devices/{}", device_id))
        .insert_header((header::AUTHORIZATION, format!("Bearer {}", access_token)))
        .to_request();
    let response = test::call_service(&app, req).await;

    assert_eq!(200, response.status().as_u16());

    let body = test::read_body(response).await;
    let response: DeviceDeleteResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(response.code, "DEVICE_DELETED");
}

#[sqlx::test]
async fn user_can_remove_session_on_another_device(pool: PgPool) {
    let app = spawn_app(pool).await;
    let (initial_access_token, _, _) = user_signs_up(&app).await;

    let devices = user_gets_list_of_devices(&app, &initial_access_token).await;
    assert_eq!(devices.len(), 1);
    let first_device_id = devices.first().unwrap().token_id;

    let (new_access_token, _) = user_logs_in(&app, "testusername", "password1_").await;

    let devices = user_gets_list_of_devices(&app, &new_access_token).await;
    assert_eq!(devices.len(), 2);
    assert_eq!(devices.first().unwrap().token_id, first_device_id);
    assert!(devices[1].token_id != first_device_id);

    user_removes_a_device(&app, &new_access_token, first_device_id).await;
}
