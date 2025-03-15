use thiserror::Error;

#[derive(Error, Debug)]
pub enum AuthError {
    #[error("Authorization header is missing")]
    MissingAuthHeader,

    #[error("Authorization header does not start with 'Bearer'")]
    InvalidAuthHeader,

    #[error("Token decoding error: {0}")]
    TokenDecodingError(#[from] jsonwebtoken::errors::Error),
}
