// Inspired by : https://github.com/actix/actix-web/issues/1147

use std::net::TcpListener;

use crate::configuration::{DatabaseSettings, Settings};
use crate::core::middlewares::token_validator::TokenValidator;
use crate::core::routes::health_check::health_check;
use crate::features::auth::routes::disable_otp::disable;
use crate::features::auth::routes::generate_otp::generate;
use crate::features::auth::routes::log_user_in::log_user_in;
use crate::features::auth::routes::recover_account_using_2fa::recover_account_using_2fa;
use crate::features::auth::routes::recover_account_using_password::recover_account_using_password;
use crate::features::auth::routes::recover_account_without_2fa_enabled::recover_account_without_2fa_enabled;
use crate::features::auth::routes::validate_otp::validate;
use crate::features::auth::routes::verify_otp::verify;

use crate::features::auth::routes::signup::register_user;
use crate::features::auth::routes::token::refresh_token;
use crate::features::profile::routes::get_profile_information::get_profile_information;
use crate::features::profile::routes::is_otp_enabled::is_otp_enabled;
use crate::features::profile::routes::post_profile_information::post_profile_information;

use crate::features::profile::routes::set_password::set_password;
use crate::features::profile::routes::update_password::update_password;
use actix_cors::Cors;
use actix_web::body::MessageBody;
use actix_web::dev::{Server, ServiceFactory, ServiceRequest, ServiceResponse};
use actix_web::http::header;
use actix_web::middleware::Logger;
use actix_web::{web, App, Error, HttpServer};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

pub fn run(listener: TcpListener, configuration: Settings) -> Result<Server, std::io::Error> {
    let server = HttpServer::new(move || create_app(&configuration))
        .listen(listener)?
        .run();

    Ok(server)
}

pub fn create_app(
    configuration: &Settings,
) -> App<
    impl ServiceFactory<
        ServiceRequest,
        Config = (),
        Response = ServiceResponse<impl MessageBody>,
        Error = Error,
        InitError = (),
    >,
> {
    let connection_pool = get_connection_pool(&configuration.database);
    let secret = &configuration.application.secret;

    let cors = Cors::default()
        .allow_any_origin()
        // .allowed_origin("localhost:3000")
        .allowed_methods(vec!["GET", "POST"])
        .allowed_headers(vec![
            header::CONTENT_TYPE,
            header::AUTHORIZATION,
            header::ACCEPT,
        ])
        .supports_credentials();

    App::new()
        .service(
            web::scope("/api")
                .service(health_check)
                .service(
                    web::scope("/auth")
                        .service(register_user)
                        .service(log_user_in)
                        .service(recover_account_without_2fa_enabled)
                        .service(recover_account_using_password)
                        .service(recover_account_using_2fa)
                        .service(refresh_token)
                        .service(
                            web::scope("/otp")
                                // Scope without middleware applied to routes that don't need it
                                .service(validate)
                                // Nested scope with middleware for protected routes
                                .service(
                                    web::scope("")
                                        .wrap(TokenValidator::new(
                                            secret.to_string(),
                                            connection_pool.clone(),
                                        ))
                                        .service(generate)
                                        .service(verify)
                                        .service(disable),
                                ),
                        ),
                )
                .service(
                    web::scope("/users")
                        // Scope without middleware applied to routes that don't need it
                        .service(is_otp_enabled)
                        // Nested scope with middleware for protected routes
                        .service(
                            web::scope("")
                                .wrap(TokenValidator::new(
                                    secret.to_string(),
                                    connection_pool.clone(),
                                ))
                                .service(get_profile_information)
                                .service(post_profile_information)
                                .service(set_password)
                                .service(update_password),
                        ),
                ),
        )
        .wrap(cors)
        .wrap(Logger::default())
        .app_data(web::Data::new(connection_pool.clone()))
        .app_data(web::Data::new(secret.clone()))
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
