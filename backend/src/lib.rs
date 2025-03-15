pub mod configuration;
pub mod startup;

pub mod features {
    pub mod auth {
        pub mod helpers {
            pub mod errors;
            pub mod token;
        }

        pub mod routes {
            pub mod login;
            pub mod otp;
            pub mod recovery;
            pub mod signup;
            pub mod token;
        }

        pub mod structs {
            pub mod models;
            pub mod requests;
            pub mod responses;
        }
    }

    pub mod profile {
        pub mod routes {
            pub mod profile;
        }

        pub mod structs {
            pub mod models;
            pub mod requests;
            pub mod responses;
        }
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
        pub mod responses;
    }
}
