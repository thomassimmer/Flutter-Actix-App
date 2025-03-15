pub mod configuration;
pub mod startup;

pub mod core {

    pub mod constants {
        pub mod errors;
    }

    pub mod routes {
        pub mod health_check;
    }

    pub mod helpers {
        pub mod mock_now;
    }

    pub mod structs {
        pub mod responses;
    }

    pub mod middlewares {
        pub mod token_validator;
    }
}

pub mod features {
    pub mod auth {
        pub mod helpers {
            pub mod errors;
            pub mod password;
            pub mod token;
            pub mod username;
        }

        pub mod routes {
            pub mod disable_otp;
            pub mod generate_otp;
            pub mod log_user_in;
            pub mod recover_account_using_2fa;
            pub mod recover_account_using_password;
            pub mod recover_account_without_2fa_enabled;
            pub mod signup;
            pub mod token;
            pub mod validate_otp;
            pub mod verify_otp;
        }

        pub mod structs {
            pub mod models;
            pub mod requests;
            pub mod responses;
        }
    }

    pub mod profile {
        pub mod routes {
            pub mod get_profile_information;
            pub mod is_otp_enabled;
            pub mod post_profile_information;
            pub mod set_password;
            pub mod update_password;
        }

        pub mod structs {
            pub mod models;
            pub mod requests;
            pub mod responses;
        }
    }
}
