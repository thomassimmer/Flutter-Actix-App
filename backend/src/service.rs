use crate::schema::users;
use crate::{
    models::{
        AppState, DisableOTPSchema, GenerateOTPSchema, User, UserLoginSchema, UserRegisterSchema,
        VerifyOTPSchema,
    },
    response::{
        GenericResponse, UserData, UserLoginWhenOtpDisabledResponse,
        UserLoginWhenOtpEnabledResponse, UserSignupResponse,
    },
};
use actix_web::{get, post, web, HttpResponse, Responder};
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use base32;
use chrono::prelude::*;
use diesel::{query_dsl::methods::FilterDsl, ExpressionMethods, OptionalExtension};
use diesel_async::RunQueryDsl;
use rand::{distributions::Alphanumeric, Rng};
use serde_json::json;
use totp_rs::{Algorithm, Secret, TOTP};
use uuid::Uuid;

#[get("/healthchecker")]
async fn health_checker_handler() -> impl Responder {
    const MESSAGE: &str = "How to  Implement Two-Factor Authentication (2FA) in Rust";

    HttpResponse::Ok().json(json!({"status": "success", "message": MESSAGE}))
}

#[post("/auth/register")]
async fn register_user_handler(
    body: web::Json<UserRegisterSchema>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut conn = match data.pool.get().await {
        Ok(conn) => conn,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Could not get database connection"}))
        }
    };

    let body = body.into_inner();
    let username_lower = body.username.to_lowercase();

    // Check if user already exists
    let existing_user = users::table
        .filter(users::username.eq(&username_lower))
        .first::<User>(&mut conn)
        .await
        .optional();

    match existing_user {
        Ok(existing_user) => {
            if existing_user.is_some() {
                let error_response = GenericResponse {
                    status: "fail".to_string(),
                    message: format!("User with username: {} already exists", username_lower),
                };
                return HttpResponse::Conflict().json(error_response);
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Database query error"}))
        }
    }

    // Hash the password
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = match argon2.hash_password(body.password.as_bytes(), &salt) {
        Ok(hash) => hash.to_string(),
        Err(_) => {
            return HttpResponse::BadRequest()
                .json(json!({"status": "fail", "message": "Failed to hash password"}))
        }
    };

    // Generate recovery codes
    let mut clear_recovery_codes = Vec::new();
    let mut hashed_recovery_codes = Vec::new();
    for _ in 0..5 {
        let code: String = rand::thread_rng()
            .sample_iter(&Alphanumeric)
            .take(16)
            .map(char::from)
            .collect();

        clear_recovery_codes.push(code.clone());

        let hashed_code = match argon2.hash_password(code.as_bytes(), &salt) {
            Ok(hash) => hash.to_string(),
            Err(_) => {
                return HttpResponse::BadRequest()
                    .json(json!({"status": "fail", "message": "Failed to hash recovery code"}))
            }
        };

        hashed_recovery_codes.push(hashed_code);
    }

    let new_user = User {
        id: Uuid::new_v4(),
        username: username_lower,
        password: password_hash,
        otp_enabled: false,
        otp_verified: false,
        otp_base32: None,
        otp_auth_url: None,
        created_at: Some(Utc::now()),
        updated_at: Some(Utc::now()),
        recovery_codes: hashed_recovery_codes,
    };

    // Insert the new user into the database
    let insert_result = diesel::insert_into(users::table)
        .values(&new_user)
        .execute(&mut conn)
        .await
        .map_err(|_| {
            HttpResponse::InternalServerError().json(
                json!({"status": "error", "message": "Failed to insert user into the database"}),
            )
        });

    match insert_result {
        Ok(inner_result) => {
            if inner_result == 0 {
                return HttpResponse::InternalServerError()
                    .json(json!({"status": "error", "message": "User registration failed"}));
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "User registration failed"}));
        }
    }

    let json_response = UserSignupResponse {
        status: "success".to_string(),
        user: user_to_response(&new_user),
        recovery_codes: clear_recovery_codes,
    };

    HttpResponse::Ok().json(json_response)
}

#[post("/auth/login")]
async fn login_user_handler(
    body: web::Json<UserLoginSchema>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut conn = match data.pool.get().await {
        Ok(conn) => conn,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Could not get database connection"}))
        }
    };

    let body = body.into_inner();
    let username_lower = body.username.to_lowercase();

    // Check if user already exists
    let existing_user = users::table
        .filter(users::username.eq(&username_lower))
        .first::<User>(&mut conn)
        .await
        .optional();

    let user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::BadRequest()
                    .json(json!({"status": "fail", "message": "Invalid email or password"}));
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Database query error"}))
        }
    };

    let parsed_hash = if let Ok(parsed_hash) = PasswordHash::new(&user.password) {
        parsed_hash
    } else {
        return HttpResponse::BadRequest()
            .json(json!({"status": "fail", "message": "Failed to retrieve hashed password"}));
    };

    let argon2 = Argon2::default();

    let is_valid = argon2
        .verify_password(body.password.as_bytes(), &parsed_hash)
        .is_ok();

    if !is_valid {
        return HttpResponse::BadRequest()
            .json(json!({"status": "fail", "message": "Invalid username or password"}));
    }

    if user.otp_enabled {
        return HttpResponse::Ok().json(UserLoginWhenOtpEnabledResponse {
            status: "success".to_string(),
            user_id: user.id.to_string(),
        });
    }

    return HttpResponse::Ok().json(UserLoginWhenOtpDisabledResponse {
        status: "success".to_string(),
        user: user_to_response(&user),
    });
}

#[post("/auth/otp/generate")]
async fn generate_otp_handler(
    body: web::Json<GenerateOTPSchema>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut conn = match data.pool.get().await {
        Ok(conn) => conn,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Could not get database connection"}))
        }
    };

    let body = body.into_inner();
    let username_lower = body.username.to_lowercase();

    // Check if user already exists
    let existing_user = users::table
        .filter(users::username.eq(&username_lower))
        .first::<User>(&mut conn)
        .await
        .optional();

    let mut user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                let json_error = GenericResponse {
                    status: "fail".to_string(),
                    message: format!("No user with Id: {} found", body.user_id),
                };

                return HttpResponse::NotFound().json(json_error);
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Database query error"}))
        }
    };

    let mut rng = rand::thread_rng();
    let data_byte: [u8; 21] = rng.gen();
    let base32_string = base32::encode(base32::Alphabet::Rfc4648 { padding: false }, &data_byte);

    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(base32_string).to_bytes().unwrap(),
    )
    .unwrap();

    let otp_base32 = totp.get_secret_base32();
    let username = body.username.to_owned();
    let issuer = "ReallyStick";
    let otp_auth_url =
        format!("otpauth://totp/{issuer}:{username}?secret={otp_base32}&issuer={issuer}");

    // let otp_auth_url = format!("otpauth://totp/<issuer>:<account_name>?secret=<secret>&issuer=<issuer>");

    user.otp_base32 = Some(otp_base32.to_owned());
    user.otp_auth_url = Some(otp_auth_url.to_owned());

    let updated_user_result =
        diesel::update(users::table.filter(users::username.eq(&username_lower)))
            .set((
                users::otp_base32.eq(user.otp_base32),
                users::otp_auth_url.eq(user.otp_auth_url),
            ))
            .execute(&mut conn)
            .await;

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(
            json!({"otp_base32":otp_base32.to_owned(), "otp_auth_url": otp_auth_url.to_owned()} ),
        ),
        Err(_) => HttpResponse::InternalServerError()
            .json(json!({"status": "error", "message": "Failed to update user"})),
    }
}

#[post("/auth/otp/verify")]
async fn verify_otp_handler(
    body: web::Json<VerifyOTPSchema>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut conn = match data.pool.get().await {
        Ok(conn) => conn,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Could not get database connection"}))
        }
    };

    let body = body.into_inner();
    let user_id = &body.user_id;

    // Check if user already exists
    let existing_user = users::table
        .filter(users::id.eq(&user_id))
        .first::<User>(&mut conn)
        .await
        .optional();

    let mut user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                let json_error = GenericResponse {
                    status: "fail".to_string(),
                    message: format!("No user with Id: {} found", body.user_id),
                };

                return HttpResponse::NotFound().json(json_error);
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Database query error"}))
        }
    };

    let otp_base32 = user.otp_base32.to_owned().unwrap();

    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(otp_base32).to_bytes().unwrap(),
    )
    .unwrap();

    let is_valid = totp.check_current(&body.token).unwrap();

    if !is_valid {
        let json_error = GenericResponse {
            status: "fail".to_string(),
            message: "Token is invalid or user doesn't exist".to_string(),
        };

        return HttpResponse::Forbidden().json(json_error);
    }

    user.otp_enabled = true;
    user.otp_verified = true;

    let updated_user_result = diesel::update(users::table.filter(users::id.eq(&user_id)))
        .set((
            users::otp_enabled.eq(user.otp_enabled),
            users::otp_verified.eq(user.otp_verified),
        ))
        .execute(&mut conn)
        .await;

    match updated_user_result {
        Ok(_) => {
            HttpResponse::Ok().json(json!({"otp_verified": true, "user": user_to_response(&user)}))
        }
        Err(_) => HttpResponse::InternalServerError()
            .json(json!({"status": "error", "message": "Failed to update user"})),
    }
}

#[post("/auth/otp/validate")]
async fn validate_otp_handler(
    body: web::Json<VerifyOTPSchema>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut conn = match data.pool.get().await {
        Ok(conn) => conn,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Could not get database connection"}))
        }
    };

    let body = body.into_inner();
    let user_id = &body.user_id;

    // Check if user already exists
    let existing_user = users::table
        .filter(users::id.eq(&user_id))
        .first::<User>(&mut conn)
        .await
        .optional();

    let user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                let json_error = GenericResponse {
                    status: "fail".to_string(),
                    message: format!("No user with Id: {} found", body.user_id),
                };

                return HttpResponse::NotFound().json(json_error);
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Database query error"}))
        }
    };

    if !user.otp_enabled {
        let json_error = GenericResponse {
            status: "fail".to_string(),
            message: "2FA not enabled".to_string(),
        };

        return HttpResponse::Forbidden().json(json_error);
    }

    let otp_base32 = user.otp_base32.to_owned().unwrap();

    let totp = TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        Secret::Encoded(otp_base32).to_bytes().unwrap(),
    )
    .unwrap();

    let is_valid = totp.check_current(&body.token).unwrap();

    if !is_valid {
        return HttpResponse::Forbidden()
            .json(json!({"status": "fail", "message": "Token is invalid or user doesn't exist"}));
    }

    HttpResponse::Ok().json(json!({"otp_valid": true}))
}

#[post("/auth/otp/disable")]
async fn disable_otp_handler(
    body: web::Json<DisableOTPSchema>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut conn = match data.pool.get().await {
        Ok(conn) => conn,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Could not get database connection"}))
        }
    };

    let body = body.into_inner();
    let user_id = &body.user_id;

    // Check if user already exists
    let existing_user = users::table
        .filter(users::id.eq(&user_id))
        .first::<User>(&mut conn)
        .await
        .optional();

    let mut user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                let json_error = GenericResponse {
                    status: "fail".to_string(),
                    message: format!("No user with Id: {} found", body.user_id),
                };

                return HttpResponse::NotFound().json(json_error);
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(json!({"status": "error", "message": "Database query error"}))
        }
    };

    user.otp_enabled = false;
    user.otp_verified = false;
    user.otp_auth_url = None;
    user.otp_base32 = None;

    let updated_user_result = diesel::update(users::table.filter(users::id.eq(&user_id)))
        .set((
            users::otp_enabled.eq(user.otp_enabled),
            users::otp_verified.eq(user.otp_verified),
            users::otp_auth_url.eq(user.otp_auth_url.clone()),
            users::otp_base32.eq(user.otp_base32.clone()),
        ))
        .execute(&mut conn)
        .await;

    match updated_user_result {
        Ok(_) => {
            HttpResponse::Ok().json(json!({"user": user_to_response(&user), "otp_disabled": true}))
        }
        Err(_) => HttpResponse::InternalServerError()
            .json(json!({"status": "error", "message": "Failed to update user"})),
    }
}

fn user_to_response(user: &User) -> UserData {
    UserData {
        id: user.id.to_owned(),
        username: user.username.to_owned(),
        otp_auth_url: user.otp_auth_url.to_owned(),
        otp_base32: user.otp_base32.to_owned(),
        otp_enabled: user.otp_enabled,
        otp_verified: user.otp_verified,
        createdAt: user.created_at.unwrap(),
        updatedAt: user.updated_at.unwrap(),
    }
}

pub fn config(conf: &mut web::ServiceConfig) {
    let scope = web::scope("/api")
        .service(health_checker_handler)
        .service(register_user_handler)
        .service(login_user_handler)
        .service(generate_otp_handler)
        .service(verify_otp_handler)
        .service(validate_otp_handler)
        .service(disable_otp_handler);

    conf.service(scope);
}
