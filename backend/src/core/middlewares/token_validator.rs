use crate::core::constants::errors::AppError;
use crate::core::helpers::mock_now::now;
use crate::features::auth::helpers::token::{get_user_token, retrieve_claims_for_token};
use crate::features::auth::structs::models::TokenCache;
use actix_web::body::EitherBody;
use actix_web::web::Data;
use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error,
};
use actix_web::{HttpMessage, HttpResponse};
use chrono::{DateTime, Duration, Utc};
use futures_util::future::LocalBoxFuture;
use sqlx::PgPool;
use std::future::{ready, Ready};
use std::rc::Rc;
use tracing::error;

pub struct TokenValidator {}

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
        }))
    }
}

pub struct TokenValidatorMiddleware<S> {
    service: Rc<S>,
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

        let secret = req.app_data::<Data<String>>().unwrap().to_string();
        let pool = req.app_data::<Data<PgPool>>().unwrap().clone();
        let cached_tokens = req.app_data::<Data<TokenCache>>().unwrap().clone();

        Box::pin(async move {
            match retrieve_claims_for_token(req.request().clone(), secret) {
                Ok(claims) => {
                    if now() > DateTime::<Utc>::from_timestamp(claims.exp, 0).unwrap() {
                        return Ok(req.into_response(
                            HttpResponse::Unauthorized()
                                .json(AppError::AccessTokenExpired.to_response())
                                .map_into_right_body(),
                        ));
                    }

                    let last_activity_for_this_token =
                        cached_tokens.get_value_for_key(claims.jti).await;

                    match last_activity_for_this_token {
                        Some(last_activity) => {
                            // Update only if last activity is more than 5 minutes ago
                            // To not update too often
                            if now() - Duration::minutes(5) > last_activity {
                                cached_tokens.update_or_insert_key(claims.jti, now()).await;
                            }
                        }
                        None => {
                            // Check if token still exists (it could have been revoked)
                            let existing_token =
                                get_user_token(&**pool, claims.user_id, claims.jti).await;

                            match existing_token {
                                Ok(r) => {
                                    if r.is_none() {
                                        return Ok(req.into_response(
                                            HttpResponse::Unauthorized()
                                                .json(AppError::InvalidAccessToken.to_response())
                                                .map_into_right_body(),
                                        ));
                                    }
                                }
                                Err(e) => {
                                    error!("Error: {}", e);
                                    return Ok(req.into_response(
                                        HttpResponse::InternalServerError()
                                            .json(AppError::DatabaseQuery.to_response())
                                            .map_into_right_body(),
                                    ));
                                }
                            };

                            cached_tokens.update_or_insert_key(claims.jti, now()).await;
                        }
                    }

                    // Store claims in request extensions for ReqData extractor
                    req.extensions_mut().insert(claims);
                    let res = service.call(req).await?;
                    Ok(res.map_into_left_body())
                }
                Err(e) => {
                    error!("Error: {}", e);
                    Ok(req.into_response(
                        HttpResponse::Unauthorized()
                            .json(AppError::InvalidAccessToken.to_response())
                            .map_into_right_body(),
                    ))
                }
            }
        })
    }
}
