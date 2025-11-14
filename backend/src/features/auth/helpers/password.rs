use crate::core::constants::errors::AppError;

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
