use thiserror::Error;

#[derive(Error, Debug)]
pub enum ProfileDomainError {
    #[error("User not found")]
    UserNotFound,

    #[error("Device not found")]
    DeviceNotFound,

    #[error("Invalid password")]
    InvalidPassword,

    #[error("Password update failed")]
    PasswordUpdateFailed,

    #[error("User update failed")]
    UserUpdateFailed,

    #[error("Password not expired")]
    PasswordNotExpired,
}

