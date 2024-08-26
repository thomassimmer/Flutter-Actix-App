pub mod configuration;
pub mod startup;

pub mod auth {
    pub mod helpers {
        pub mod error;
        pub mod serializer;
        pub mod token;
    }

    pub mod routes {
        pub mod login;
        pub mod otp;
        pub mod profile;
        pub mod signup;
        pub mod token;
    }

    pub mod structs {
        pub mod model;
        pub mod request;
        pub mod response;
    }
}

pub mod core {
    pub mod routes {
        pub mod health_check;
    }

    pub mod helpers {
        pub mod mock_now;
    }

    pub mod structs {
        pub mod response;
    }
}
