use argon2::{Argon2, PasswordHash, PasswordVerifier};

use crate::features::profile::structs::models::User;

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
