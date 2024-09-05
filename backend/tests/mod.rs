pub mod auth {
    pub mod login;
    pub mod otp;
    pub mod recovery {
        pub mod recover_account_using_2fa;
        pub mod recover_account_using_password;
        pub mod recover_account_without_2fa_enabled;
    }
    pub mod signup;
    pub mod token;
}

pub mod profile {
    pub mod profile;
    pub mod set_password;
    pub mod update_password;
}

pub mod core {
    pub mod health_check;
}

pub mod helpers;
