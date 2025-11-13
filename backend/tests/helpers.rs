use actix_http::Request;
use actix_web::{
    body::MessageBody,
    dev::{Service, ServiceResponse},
    test::init_service,
    Error,
};
use flutteractixapp::{
    configuration::get_configuration, features::auth::structs::models::TokenCache,
    startup::create_app,
};
use sqlx::PgPool;
use uuid::Uuid;

pub async fn spawn_app(
    pool: PgPool,
) -> impl Service<Request, Response = ServiceResponse<impl MessageBody>, Error = Error> {
    // Randomise configuration to ensure test isolation
    let configuration = {
        let mut c = get_configuration().expect("Failed to read configuration.");
        // Use a different database for each test case
        c.database.database_name = Uuid::new_v4().to_string();
        // Use a random OS port
        c.application.port = 0;
        c
    };

    let token_cache = TokenCache::default();
    let secret = configuration.application.secret;

    init_service(create_app(
        pool.clone(),
        secret.clone(),
        token_cache.clone(),
    ))
    .await
}
