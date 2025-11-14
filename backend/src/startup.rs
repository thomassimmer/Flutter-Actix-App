// Inspired by : https://github.com/actix/actix-web/issues/1147

use std::net::TcpListener;

use crate::configuration::{DatabaseSettings, Settings};
use crate::core::middlewares::token_validator::TokenValidator;
use crate::core::routes::health_check::health_check;
use crate::features::auth::application::usecases::{
    DisableOtpUseCase, GenerateOtpUseCase, LoginUseCase, LogoutUseCase,
    RecoverAccountUsing2FAUseCase, RecoverAccountUsingPasswordUseCase,
    RecoverAccountWithout2FAEnabledUseCase, RefreshTokenUseCase, SignupUseCase,
    ValidateOtpUseCase, VerifyOtpUseCase,
};
use crate::features::auth::infrastructure::repositories::{
    TokenRepositoryImpl, TokenServiceImpl, UserRepositoryImpl,
};
use crate::features::auth::presentation::controllers::{
    disable_otp, generate_otp, login, logout, recover_account_using_2fa,
    recover_account_using_password, recover_account_without_2fa_enabled, refresh_token, signup,
    validate_otp, verify_otp,
};
use crate::features::auth::structs::models::TokenCache;
use crate::features::profile::application::usecases::{
    DeleteDeviceUseCase, GetDevicesUseCase, GetProfileUseCase, IsOtpEnabledUseCase,
    SetPasswordUseCase, UpdatePasswordUseCase, UpdateProfileUseCase,
};
use crate::features::profile::infrastructure::repositories::{
    DeviceRepositoryImpl, UserRepositoryImpl as ProfileUserRepositoryImpl,
};
use crate::features::profile::presentation::controllers::{
    delete_device, get_devices, get_profile, is_otp_enabled, set_password, update_password,
    update_profile,
};
use actix_cors::Cors;
use actix_http::header::HeaderName;
use actix_web::body::MessageBody;
use actix_web::dev::{Server, ServiceFactory, ServiceRequest, ServiceResponse};
use actix_web::http::header;
use actix_web::middleware::Logger;
use actix_web::{web, App, Error, HttpServer};
use sqlx::postgres::PgPoolOptions;
use sqlx::{PgPool, Pool, Postgres};

pub fn run(listener: TcpListener, configuration: Settings) -> Result<Server, std::io::Error> {
    let token_cache = TokenCache::default();
    let connection_pool = get_connection_pool(&configuration.database);
    let secret = configuration.application.secret;

    let server = HttpServer::new(move || {
        create_app(connection_pool.clone(), secret.clone(), token_cache.clone())
    })
    .listen(listener)?
    .run();

    Ok(server)
}

pub fn create_app(
    connection_pool: Pool<Postgres>,
    secret: String,
    token_cache: TokenCache,
) -> App<
    impl ServiceFactory<
        ServiceRequest,
        Config = (),
        Response = ServiceResponse<impl MessageBody>,
        Error = Error,
        InitError = (),
    >,
> {
    let cors = Cors::default()
        .allow_any_origin()
        // .allowed_origin("localhost:3000")
        .allowed_methods(vec!["GET", "POST", "DELETE"])
        .allowed_headers(vec![
            header::CONTENT_TYPE,
            header::AUTHORIZATION,
            header::ACCEPT,
            HeaderName::from_static("x-user-agent"),
        ])
        .supports_credentials();

    // Initialize repositories
    let user_repo_impl = UserRepositoryImpl::new(connection_pool.clone());
    let token_repo_impl = TokenRepositoryImpl::new(connection_pool.clone());
    let token_service_impl = TokenServiceImpl::new(secret.as_bytes().to_vec());

    // Initialize use cases
    let signup_use_case = SignupUseCase::new(
        Box::new(user_repo_impl.clone()),
        Box::new(token_repo_impl.clone()),
        Box::new(token_service_impl.clone()),
        secret.as_bytes().to_vec(),
    );
    let login_use_case = LoginUseCase::new(
        Box::new(user_repo_impl.clone()),
        Box::new(token_repo_impl.clone()),
        Box::new(token_service_impl.clone()),
    );
    let refresh_token_use_case = RefreshTokenUseCase::new(
        Box::new(token_repo_impl.clone()),
        Box::new(token_service_impl.clone()),
    );
    let generate_otp_use_case = GenerateOtpUseCase::new(Box::new(user_repo_impl.clone()));
    let verify_otp_use_case = VerifyOtpUseCase::new(Box::new(user_repo_impl.clone()));
    let validate_otp_use_case = ValidateOtpUseCase::new(
        Box::new(user_repo_impl.clone()),
        Box::new(token_repo_impl.clone()),
        Box::new(token_service_impl.clone()),
    );
    let disable_otp_use_case = DisableOtpUseCase::new(Box::new(user_repo_impl.clone()));
    let logout_use_case = LogoutUseCase::new(Box::new(token_repo_impl.clone()), token_cache.clone());
    let recover_account_without_2fa_enabled_use_case = RecoverAccountWithout2FAEnabledUseCase::new(
        Box::new(user_repo_impl.clone()),
        Box::new(token_repo_impl.clone()),
        Box::new(token_service_impl.clone()),
    );
    let recover_account_using_password_use_case = RecoverAccountUsingPasswordUseCase::new(
        Box::new(user_repo_impl.clone()),
        Box::new(token_repo_impl.clone()),
        Box::new(token_service_impl.clone()),
    );
    let recover_account_using_2fa_use_case = RecoverAccountUsing2FAUseCase::new(
        Box::new(user_repo_impl.clone()),
        Box::new(token_repo_impl.clone()),
        Box::new(token_service_impl.clone()),
    );

    // Initialize profile repositories
    let profile_user_repo_impl = ProfileUserRepositoryImpl::new(connection_pool.clone());
    let device_repo_impl = DeviceRepositoryImpl::new(connection_pool.clone());

    // Initialize profile use cases
    let get_profile_use_case = GetProfileUseCase::new(Box::new(profile_user_repo_impl.clone()));
    let update_profile_use_case =
        UpdateProfileUseCase::new(Box::new(profile_user_repo_impl.clone()));
    let set_password_use_case = SetPasswordUseCase::new(Box::new(profile_user_repo_impl.clone()));
    let update_password_use_case =
        UpdatePasswordUseCase::new(Box::new(profile_user_repo_impl.clone()));
    let get_devices_use_case = GetDevicesUseCase::new(
        Box::new(device_repo_impl.clone()),
        token_cache.clone(),
    );
    let delete_device_use_case = DeleteDeviceUseCase::new(Box::new(device_repo_impl));
    let is_otp_enabled_use_case = IsOtpEnabledUseCase::new(Box::new(profile_user_repo_impl.clone()));

    App::new()
        .service(
            web::scope("/api")
                .service(health_check)
                .service(
                    web::scope("/auth")
                        .service(signup)
                        .service(login)
                        .service(recover_account_without_2fa_enabled)
                        .service(recover_account_using_password)
                        .service(recover_account_using_2fa)
                        .service(refresh_token)
                        .service(
                            web::scope("/logout")
                                .wrap(TokenValidator {})
                                .service(logout),
                        )
                        .service(
                            web::scope("/otp")
                                // Scope without middleware applied to routes that don't need it
                                .service(validate_otp)
                                // Nested scope with middleware for protected routes
                                .service(
                                    web::scope("")
                                        .wrap(TokenValidator {})
                                        .service(generate_otp)
                                        .service(verify_otp)
                                        .service(disable_otp),
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
                                .wrap(TokenValidator {})
                                .service(get_profile)
                                .service(update_profile)
                                .service(set_password)
                                .service(update_password),
                        ),
                )
                .service(
                    web::scope("/devices")
                        .wrap(TokenValidator {})
                        .service(get_devices)
                        .service(delete_device),
                ),
        )
        .wrap(cors)
        .wrap(Logger::default())
        .app_data(web::Data::new(connection_pool))
        .app_data(web::Data::new(secret))
        .app_data(web::Data::new(token_cache))
        .app_data(web::Data::new(signup_use_case))
        .app_data(web::Data::new(login_use_case))
        .app_data(web::Data::new(refresh_token_use_case))
        .app_data(web::Data::new(generate_otp_use_case))
        .app_data(web::Data::new(verify_otp_use_case))
        .app_data(web::Data::new(validate_otp_use_case))
        .app_data(web::Data::new(disable_otp_use_case))
        .app_data(web::Data::new(logout_use_case))
        .app_data(web::Data::new(recover_account_without_2fa_enabled_use_case))
        .app_data(web::Data::new(recover_account_using_password_use_case))
        .app_data(web::Data::new(recover_account_using_2fa_use_case))
        .app_data(web::Data::new(get_profile_use_case))
        .app_data(web::Data::new(update_profile_use_case))
        .app_data(web::Data::new(set_password_use_case))
        .app_data(web::Data::new(update_password_use_case))
        .app_data(web::Data::new(is_otp_enabled_use_case))
        .app_data(web::Data::new(get_devices_use_case))
        .app_data(web::Data::new(delete_device_use_case))
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
