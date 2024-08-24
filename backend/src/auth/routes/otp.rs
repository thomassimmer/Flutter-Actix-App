use crate::auth::helpers::token::{generate_tokens, retrieve_claims_for_token};
use crate::models::{UserToken, ValidateOTPSchema};
use crate::response::{
    DisableOtpResponse, GenerateOtpResponse, UserLoginResponse, VerifyOtpResponse,
};
use crate::{
    models::{User, VerifyOTPSchema},
    response::GenericResponse,
};
use actix_web::{get, post, web, HttpRequest, HttpResponse, Responder};

use base32;
use chrono::{DateTime, Utc};
use rand::Rng;
use sqlx::PgPool;
use totp_rs::{Algorithm, Secret, TOTP};
use uuid::Uuid;

#[get("generate")]
pub async fn generate(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    match retrieve_claims_for_token(req, secret.to_string()) {
        Ok(claims) => {
            let mut transaction = match pool.begin().await {
                Ok(t) => t,
                Err(_) => {
                    return HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "Failed to get a transaction".to_string(),
                    })
                }
            };

            // Check if user already exists
            let existing_user = sqlx::query_as!(
                User,
                r#"
                SELECT u.*
                FROM users u
                JOIN user_tokens ut ON u.id = ut.user_id
                WHERE ut.token_id = $1
                "#,
                claims.jti,
            )
            .fetch_optional(&mut *transaction)
            .await;

            let mut user = match existing_user {
                Ok(existing_user) => {
                    if let Some(user) = existing_user {
                        user
                    } else {
                        return HttpResponse::NotFound().json(GenericResponse {
                            status: "fail".to_string(),
                            message: "No user with this token".to_string(),
                        });
                    }
                }
                Err(_) => {
                    return HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "Database query error".to_string(),
                    })
                }
            };

            let mut rng = rand::thread_rng();
            let data_byte: [u8; 21] = rng.gen();
            let base32_string =
                base32::encode(base32::Alphabet::Rfc4648 { padding: false }, &data_byte);

            let totp = TOTP::new(
                Algorithm::SHA1,
                6,
                1,
                30,
                Secret::Encoded(base32_string).to_bytes().unwrap(),
            )
            .unwrap();

            let otp_base32 = totp.get_secret_base32();
            let username = user.username.to_owned();
            let issuer = "ReallyStick";

            // Format should be:
            // let otp_auth_url = format!("otpauth://totp/<issuer>:<account_name>?secret=<secret>&issuer=<issuer>");
            let otp_auth_url =
                format!("otpauth://totp/{issuer}:{username}?secret={otp_base32}&issuer={issuer}");

            user.otp_base32 = Some(otp_base32.to_owned());
            user.otp_auth_url = Some(otp_auth_url.to_owned());

            let updated_user_result = sqlx::query!(
                r#"
                UPDATE users
                SET otp_base32 = $1, otp_auth_url = $2
                WHERE id = $3
                "#,
                user.otp_base32,
                user.otp_auth_url,
                user.id
            )
            .fetch_optional(&mut *transaction)
            .await;

            if (transaction.commit().await).is_err() {
                return HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to commit transaction".to_string(),
                });
            }

            match updated_user_result {
                Ok(_) => HttpResponse::Ok().json(GenerateOtpResponse {
                    status: "success".to_string(),
                    otp_base32: otp_base32.to_owned(),
                    otp_auth_url: otp_auth_url.to_owned(),
                }),
                Err(_) => HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to update user".to_string(),
                }),
            }
        }
        Err(e) => HttpResponse::Unauthorized().json(GenericResponse {
            status: "fail".to_string(),
            message: e.to_string(),
        }),
    }
}

#[post("/verify")]
pub async fn verify(
    req: HttpRequest,
    body: web::Json<VerifyOTPSchema>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    match retrieve_claims_for_token(req, secret.to_string()) {
        Ok(claims) => {
            let mut transaction = match pool.begin().await {
                Ok(t) => t,
                Err(_) => {
                    return HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "Failed to get a transaction".to_string(),
                    })
                }
            };

            // Check if user already exists
            let existing_user = sqlx::query_as!(
                User,
                r#"
                SELECT u.*
                FROM users u
                JOIN user_tokens ut ON u.id = ut.user_id
                WHERE ut.token_id = $1
                "#,
                claims.jti,
            )
            .fetch_optional(&mut *transaction)
            .await;

            let mut user = match existing_user {
                Ok(existing_user) => {
                    if let Some(user) = existing_user {
                        user
                    } else {
                        return HttpResponse::NotFound().json(GenericResponse {
                            status: "fail".to_string(),
                            message: "No user with this token".to_string(),
                        });
                    }
                }
                Err(_) => {
                    return HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "Database query error".to_string(),
                    })
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

            let is_valid = totp.check_current(&body.code).unwrap();

            if !is_valid {
                let json_error = GenericResponse {
                    status: "fail".to_string(),
                    message: "Token is invalid or user doesn't exist".to_string(),
                };

                return HttpResponse::Forbidden().json(json_error);
            }

            user.otp_enabled = true;
            user.otp_verified = true;

            let updated_user_result = sqlx::query_scalar!(
                r#"
                UPDATE users
                SET otp_enabled = $1, otp_verified = $2
                WHERE id = $3
                "#,
                user.otp_enabled,
                user.otp_verified,
                user.id
            )
            .fetch_optional(&mut *transaction)
            .await;

            if (transaction.commit().await).is_err() {
                return HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to commit transaction".to_string(),
                });
            }

            match updated_user_result {
                Ok(_) => HttpResponse::Ok().json(VerifyOtpResponse {
                    status: "success".to_string(),
                    otp_verified: true,
                }),
                Err(_) => HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to update user".to_string(),
                }),
            }
        }
        Err(e) => HttpResponse::Unauthorized().json(GenericResponse {
            status: "fail".to_string(),
            message: e.to_string(),
        }),
    }
}

#[post("/validate")]
async fn validate(
    body: web::Json<ValidateOTPSchema>,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Failed to get a transaction".to_string(),
            })
        }
    };

    let body = body.into_inner();
    let user_id = Uuid::parse_str(&body.user_id).unwrap();

    // Check if user already exists
    let existing_user = sqlx::query_as!(
        User,
        r#"
        SELECT *
        FROM users
        WHERE id = $1
        "#,
        user_id,
    )
    .fetch_optional(&mut *transaction)
    .await;

    let user = match existing_user {
        Ok(existing_user) => {
            if let Some(user) = existing_user {
                user
            } else {
                return HttpResponse::NotFound().json(GenericResponse {
                    status: "fail".to_string(),
                    message: format!("No user with id: {} found", body.user_id),
                });
            }
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(GenericResponse {
                status: "error".to_string(),
                message: "Database query error".to_string(),
            })
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

    let is_valid = totp.check_current(&body.code).unwrap();

    if !is_valid {
        return HttpResponse::Forbidden().json(GenericResponse {
            status: "fail".to_string(),
            message: "Token is invalid or user doesn't exist".to_string(),
        });
    }

    let jti = Uuid::new_v4().to_string();
    let (access_token, refresh_token, claim) = generate_tokens(secret.as_bytes(), jti);

    let new_token = UserToken {
        id: Uuid::new_v4(),
        user_id: user.id,
        token_id: claim.jti,
        expires_at: DateTime::<Utc>::from_timestamp(claim.exp as i64, 0).unwrap(),
    };

    // Insert the new user token into the database
    let insert_result = sqlx::query!(
        r#"
        INSERT INTO user_tokens (id, user_id, token_id, expires_at)
        VALUES ($1, $2, $3, $4)
        "#,
        new_token.id,
        new_token.user_id,
        new_token.token_id,
        new_token.expires_at,
    )
    .execute(&mut *transaction)
    .await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to commit transaction".to_string(),
        });
    }

    if insert_result.is_err() {
        return HttpResponse::InternalServerError().json(GenericResponse {
            status: "error".to_string(),
            message: "Failed to insert user token into the database".to_string(),
        });
    }

    HttpResponse::Ok().json(UserLoginResponse {
        status: "success".to_string(),
        access_token,
        refresh_token,
        expires_in: claim.exp,
    })
}

#[get("/disable")]
async fn disable(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
) -> impl Responder {
    match retrieve_claims_for_token(req, secret.to_string()) {
        Ok(claims) => {
            let mut transaction = match pool.begin().await {
                Ok(t) => t,
                Err(_) => {
                    return HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "Failed to get a transaction".to_string(),
                    })
                }
            };

            // Check if user already exists
            let existing_user = sqlx::query_as!(
                User,
                r#"
                SELECT u.*
                FROM users u
                JOIN user_tokens ut ON u.id = ut.user_id
                WHERE ut.token_id = $1
                "#,
                claims.jti,
            )
            .fetch_optional(&mut *transaction)
            .await;

            let mut user = match existing_user {
                Ok(existing_user) => {
                    if let Some(user) = existing_user {
                        user
                    } else {
                        return HttpResponse::NotFound().json(GenericResponse {
                            status: "fail".to_string(),
                            message: "No user with this token".to_string(),
                        });
                    }
                }
                Err(_) => {
                    return HttpResponse::InternalServerError().json(GenericResponse {
                        status: "error".to_string(),
                        message: "Database query error".to_string(),
                    })
                }
            };

            user.otp_enabled = false;
            user.otp_verified = false;
            user.otp_auth_url = None;
            user.otp_base32 = None;

            let updated_user_result = sqlx::query_scalar!(
                r#"
                UPDATE users
                SET otp_enabled = $1, otp_verified = $2, otp_auth_url = $3, otp_base32 = $4
                WHERE id = $5
                "#,
                user.otp_enabled,
                user.otp_verified,
                user.otp_auth_url,
                user.otp_base32,
                user.id
            )
            .fetch_optional(&mut *transaction)
            .await;

            if (transaction.commit().await).is_err() {
                return HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to commit transaction".to_string(),
                });
            }

            match updated_user_result {
                Ok(_) => HttpResponse::Ok().json(DisableOtpResponse {
                    status: "success".to_string(),
                    otp_enabled: false,
                }),
                Err(_) => HttpResponse::InternalServerError().json(GenericResponse {
                    status: "error".to_string(),
                    message: "Failed to update user".to_string(),
                }),
            }
        }

        Err(e) => HttpResponse::Unauthorized().json(GenericResponse {
            status: "fail".to_string(),
            message: e.to_string(),
        }),
    }
}
