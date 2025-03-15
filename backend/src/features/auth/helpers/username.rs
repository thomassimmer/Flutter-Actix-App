use crate::core::constants::errors::AppError;
use regex::Regex;

pub fn username_has_the_good_size(input: &str) -> bool {
    input.len() >= 3 && input.len() <= 20
}

pub fn username_respects_conventions(input: &str) -> bool {
    // This regex means:
    // •	Starts with an alphanumeric character.
    // •	Allows alphanumeric characters, optionally separated by a single period, underscore, or hyphen.
    // •	Does not allow consecutive special characters.
    // •	Ends with an alphanumeric character.

    let pattern = Regex::new(r"^[a-zA-Z0-9]([._-]?[a-zA-Z0-9]+)*$").unwrap();

    pattern.is_match(input)
}

pub fn is_username_valid(input: &str) -> Option<AppError> {
    if !username_has_the_good_size(input) {
        return Some(AppError::UsernameWrongSize);
    }

    if !username_respects_conventions(input) {
        return Some(AppError::UsernameNotRespectingRules);
    }

    None
}
