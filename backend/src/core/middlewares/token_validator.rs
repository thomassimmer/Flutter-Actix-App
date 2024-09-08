use crate::core::constants::errors::AppError;
use crate::core::helpers::mock_now::now;
use crate::features::auth::helpers::token::retrieve_claims_for_token;
use crate::features::profile::structs::models::User;
use actix_web::body::EitherBody;
use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error,
};
use actix_web::{HttpMessage, HttpResponse};
use chrono::{DateTime, Utc};
use futures_util::future::LocalBoxFuture;
use sqlx::PgPool;
use std::future::{ready, Ready};
use std::rc::Rc;

pub struct TokenValidator {
    pub secret: Rc<String>,
    pub pool: Rc<PgPool>,
}

impl TokenValidator {
    pub fn new(secret: String, pool: PgPool) -> Self {
        TokenValidator {
            secret: Rc::new(secret),
            pool: Rc::new(pool),
        }
    }
}

impl<S, B> Transform<S, ServiceRequest> for TokenValidator
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Transform = TokenValidatorMiddleware<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(TokenValidatorMiddleware {
            service: Rc::new(service),
            secret: Rc::new(self.secret.to_string()),
            pool: self.pool.clone(),
        }))
    }
}

pub struct TokenValidatorMiddleware<S> {
    service: Rc<S>,
    secret: Rc<String>,
    pool: Rc<PgPool>,
}

impl<S, B> Service<ServiceRequest> for TokenValidatorMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = Rc::clone(&self.service);
        let secret = Rc::clone(&self.secret);
        let pool = Rc::clone(&self.pool);

        Box::pin(async move {
            match retrieve_claims_for_token(req.request().clone(), secret.to_string()) {
                Ok(claims) => {
                    if now() > DateTime::<Utc>::from_timestamp(claims.exp, 0).unwrap() {
                        return Ok(req.into_response(
                            HttpResponse::Unauthorized()
                                .json(AppError::AccessTokenExpired.to_response())
                                .map_into_right_body(),
                        ));
                    }

                    let mut transaction = match pool.begin().await {
                        Ok(t) => t,
                        Err(_) => {
                            return Ok(req.into_response(
                                HttpResponse::InternalServerError()
                                    .json(AppError::DatabaseConnection.to_response())
                                    .map_into_right_body(),
                            ));
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

                    let user = match existing_user {
                        Ok(existing_user) => {
                            if let Some(user) = existing_user {
                                user
                            } else {
                                return Ok(req.into_response(
                                    HttpResponse::Unauthorized()
                                        .json(AppError::InvalidAccessToken.to_response())
                                        .map_into_right_body(),
                                ));
                            }
                        }
                        Err(_) => {
                            return Ok(req.into_response(
                                HttpResponse::InternalServerError()
                                    .json(AppError::DatabaseQuery.to_response())
                                    .map_into_right_body(),
                            ));
                        }
                    };

                    // Store user in request extensions
                    req.extensions_mut().insert(user);
                    let res = service.call(req).await?;
                    Ok(res.map_into_left_body())
                }
                Err(_) => Ok(req.into_response(
                    HttpResponse::Unauthorized()
                        .json(AppError::InvalidAccessToken.to_response())
                        .map_into_right_body(),
                )),
            }
        })
    }
}
