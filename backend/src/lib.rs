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
        pub mod application {
            pub mod dto;
            pub mod usecases;
        }

        pub mod domain {
            pub mod entities;
            pub mod errors;
            pub mod repositories;
        }

        pub mod helpers {
            pub mod errors;
            pub mod password;
            pub mod token;
            pub mod username;
        }

        pub mod infrastructure {
            pub mod models;
            pub mod repositories;
        }

        pub mod presentation {
            pub mod controllers;
        }

        pub mod structs {
            pub mod models;
        }
    }

    pub mod profile {
        pub mod application {
            pub mod dto;
            pub mod usecases;
        }

        pub mod domain {
            pub mod entities;
            pub mod errors;
            pub mod repositories;
        }

        pub mod helpers {
            pub mod device_info;
        }

        pub mod infrastructure {
            pub mod models;
            pub mod repositories;
        }

        pub mod presentation {
            pub mod controllers;
        }

        pub mod structs {
            pub mod models;
        }
    }
}
