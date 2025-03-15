use crate::profile::structs::model::{User, UserData};

pub fn user_to_response(user: &User) -> UserData {
    UserData {
        id: user.id,
        username: user.username.to_owned(),
        locale: user.locale.to_owned(),
        otp_auth_url: user.otp_auth_url.to_owned(),
        otp_base32: user.otp_base32.to_owned(),
        otp_enabled: user.otp_enabled,
        otp_verified: user.otp_verified,
        createdAt: user.created_at,
        updatedAt: user.updated_at,
    }
}
