use crate::{core::constants::errors::AppError, features::profile::structs::models::User};
use argon2::{Argon2, PasswordHash, PasswordVerifier};

pub fn password_is_valid(user: &User, password: &str) -> bool {
    let parsed_hash = if let Ok(parsed_hash) = PasswordHash::new(&user.password) {
        parsed_hash
    } else {
        return false;
    };

    let argon2 = Argon2::default();

    let is_valid = argon2
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok();

    is_valid
}

pub fn password_is_long_enough(input: &str) -> bool {
    input.len() >= 8
}

pub fn password_is_strong_enough(input: &str) -> bool {
    let has_letter = input.chars().any(|c| c.is_ascii_alphabetic());
    let has_digit = input.chars().any(|c| c.is_ascii_digit());
    let has_special = input.chars().any(|c| "@$!%*?&_".contains(c));
    let valid_characters = input
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || "@$!%*?&_".contains(c));

    has_letter && has_digit && has_special && valid_characters
}

pub fn is_password_valid(input: &str) -> Option<AppError> {
    if !password_is_long_enough(input) {
        return Some(AppError::PasswordTooShort);
    }

    if !password_is_strong_enough(input) {
        return Some(AppError::PasswordTooWeak);
    }

    None
}
