use crate::core::helpers::mock_now::now;
use crate::core::structs::responses::GenericResponse;
use crate::features::auth::helpers::token::retrieve_claims_for_token;
use actix_web::body::EitherBody;
use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error,
};
use actix_web::{HttpMessage, HttpResponse};
use chrono::{DateTime, Utc};
use futures_util::future::LocalBoxFuture;
use std::future::{ready, Ready};
use std::rc::Rc;

pub struct TokenValidator {
    pub secret: Rc<String>,
}

impl TokenValidator {
    pub fn new(secret: String) -> Self {
        TokenValidator {
            secret: Rc::new(secret),
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
        }))
    }
}

pub struct TokenValidatorMiddleware<S> {
    service: Rc<S>,
    secret: Rc<String>,
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
        let secret = Rc::clone(&self.secret);
        let service = Rc::clone(&self.service);

        Box::pin(async move {
            match retrieve_claims_for_token(req.request().clone(), secret.to_string()) {
                Ok(claims) => {
                    if now() > DateTime::<Utc>::from_timestamp(claims.exp as i64, 0).unwrap() {
                        return Ok(req.into_response(
                            HttpResponse::Unauthorized()
                                .json(GenericResponse {
                                    status: "error".to_string(),
                                    message: "Token expired".to_string(),
                                })
                                .map_into_right_body(),
                        ));
                    }

                    // Store claims in request extensions
                    req.extensions_mut().insert(claims);
                    let res = service.call(req).await?;
                    Ok(res.map_into_left_body())
                }
                Err(_) => {
                    return Ok(req.into_response(
                        HttpResponse::Unauthorized()
                            .json(GenericResponse {
                                status: "fail".to_string(),
                                message: "Invalid access token".to_string(),
                            })
                            .map_into_right_body(),
                    ));
                }
            }
        })
    }
}
