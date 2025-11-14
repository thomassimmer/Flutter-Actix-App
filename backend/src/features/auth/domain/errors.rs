use thiserror::Error;

#[derive(Error, Debug)]
pub enum AuthDomainError {
    #[error("Invalid username or password")]
    InvalidCredentials,

    #[error("User not found")]
    UserNotFound,

    #[error("User already exists")]
    UserAlreadyExists,

    #[error("Invalid one-time password")]
    InvalidOtp,

    #[error("Invalid recovery code")]
    InvalidRecoveryCode,

    #[error("Invalid username or recovery code")]
    InvalidUsernameOrRecoveryCode,

    #[error("Invalid username or password or recovery code")]
    InvalidUsernameOrPasswordOrRecoveryCode,

    #[error("Invalid username or code or recovery code")]
    InvalidUsernameOrCodeOrRecoveryCode,

    #[error("Token expired")]
    TokenExpired,

    #[error("Invalid token")]
    InvalidToken,

    #[error("Two-factor authentication not enabled")]
    OtpNotEnabled,

    #[error("Two-factor authentication not enabled")]
    TwoFactorAuthenticationNotEnabled,

    #[error("Password expired")]
    PasswordExpired,

    #[error("Invalid password")]
    InvalidPassword,

    #[error("Database error")]
    DatabaseError,
}

