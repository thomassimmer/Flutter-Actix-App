pub mod configuration;
pub mod models;
pub mod response;
pub mod startup;

pub mod auth {
    pub mod helpers {
        pub mod errors;
        pub mod token;
    }

    pub mod routes {
        pub mod login;
        pub mod otp;
        pub mod profile;
        pub mod signup;
        pub mod token;
    }
}

pub mod core {
    pub mod routes {
        pub mod health_check;
    }

    pub mod helpers {
        pub mod mock_now;
    }
}
