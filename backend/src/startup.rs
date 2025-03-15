use std::net::TcpListener;

use crate::auth::routes::login::log_user_in;
use crate::auth::routes::profile::get_profile_information;
use crate::auth::routes::signup::register_user;
use crate::auth::routes::token::refresh_token;
use crate::configuration::{DatabaseSettings, Settings};
use crate::core::routes::health_check::health_check;
use actix_web::dev::Server;
use actix_web::{web, App, HttpServer};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

pub fn run(listener: TcpListener, configuration: Settings) -> Result<Server, std::io::Error> {
    // Wrap the pool using web::Data, which boils down to an Arc smart pointer
    let connection_pool = get_connection_pool(&configuration.database);
    let secret = configuration.application.secret;

    // let cors = Cors::default()
    //     .allow_any_origin()
    //     // .allowed_origin("localhost:3000")
    //     .allowed_methods(vec!["GET", "POST"])
    //     .allowed_headers(vec![
    //         header::CONTENT_TYPE,
    //         header::AUTHORIZATION,
    //         header::ACCEPT,
    //     ])
    //     .supports_credentials();

    let server = HttpServer::new(move || {
        App::new()
            // .wrap(cors)
            .route("/health_check", web::get().to(health_check))
            .route("/auth/register", web::post().to(register_user))
            .route("/auth/login", web::post().to(log_user_in))
            .route("/auth/refresh-token", web::post().to(refresh_token))
            .route("/users/me", web::get().to(get_profile_information))
            .app_data(web::Data::new(connection_pool.clone()))
            .app_data(web::Data::new(secret.clone()))
    })
    .listen(listener)?
    .run();
    Ok(server)
}

pub struct Application {
    port: u16,
    server: Server,
}

impl Application {
    pub async fn build(configuration: Settings) -> Result<Self, std::io::Error> {
        let address = format!(
            "{}:{}",
            configuration.application.host, configuration.application.port
        );
        let listener = TcpListener::bind(address)?;
        let port = listener.local_addr().unwrap().port();
        let server = run(listener, configuration).unwrap();

        Ok(Self { port, server })
    }

    pub fn port(&self) -> u16 {
        self.port
    }

    pub async fn run_until_stopped(self) -> Result<(), std::io::Error> {
        self.server.await
    }
}

pub fn get_connection_pool(configuration: &DatabaseSettings) -> PgPool {
    PgPoolOptions::new().connect_lazy_with(configuration.with_db())
}
