# Building a Cross-Platform App with Flutter and Rust: Clean Architecture

## Introduction

This article explains the architecture I implemented to build a cross-platform app using Flutter for the frontend and Actix for the backend. The app includes key features such as:

1. A login/signup page using a username and password (without email, for privacy).
2. A recovery code page for new users.
3. A 2FA setup page using OTP with an external app like Google Authenticator.
4. A main app view with four tabs.
5. A profile tab where users can change settings like language, theme, 2FA and logout.
6. An account recovery page for users who lose access to 2FA or their password.

For more context, feel free to check out [the first article](https://medium.com/@thomas.simmer/building-a-cross-platform-app-with-flutter-and-rust-a-beginners-journey-92cbb893c2f9) of this series.

## Docker Architecture and Containers

In this project, I used three Docker containers, managed via a docker-compose.yml file, to provide consistency across different environments, enabling seamless deployment regardless of the platform:

- Frontend container: Hosts the Flutter web app.
- Backend container: Runs the Actix API.
- Database container: Uses PostgreSQL for persistent storage.

This architecture allows for scalability. For example, if the app experiences heavy usage, I can scale the backend independently by increasing the number of API containers without needing to modify the frontend or database containers. I can also update only the frontend containers if I need to deploy a new version of the flutter code.

Here’s a high-level overview of the global architecture:

```
.
├── README.md
├── backend
│   ├── .env
│   ├── Cargo.toml
│   ├── Dockerfile
│   ├── configuration
│   ├── migrations
│   ├── src
│   │   ├── core
│   │   ├── features
│   │   ├── lib.rs
│   │   ├── main.rs
│   └── tests
├── db
│   ├── .env
│   └── Dockerfile
├── docker-compose.yml
└── frontend
    ├── Dockerfile
    ├── lib
    │   ├── core
    │   ├── features
    ├── pubspec.yaml
    └── ...
```

The docker-compose.yml file contains:

```yml
services:
  frontend:
    container_name: template_frontend
    image: template_frontend
    build:
      context: ./frontend
    env_file:
      - ./frontend/.env
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
    networks:
      - app-network

  backend:
    container_name: template_backend
    image: template_backend
    build:
      context: ./backend
      dockerfile: Dockerfile
    env_file:
      - ./backend/.env.docker
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    networks:
      - app-network

  db:
    container_name: template_db
    image: template_db
    build:
      context: ./db
      dockerfile: Dockerfile
    env_file:
      - ./db/.env
    volumes:
      - ./postgres_data:/var/lib/postgresql/data # This is to quickly move/delete my volume if I need
    ports:
      - 5432:5432
    expose:
      - "5432"
    command: -p 5432
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

As shown above, I’ve utilized a bridge network to ensure that only my containers can communicate with each other locally. This setup isolates the network traffic, preventing other containers running on the same machine from interacting with these services. It’s an essential security measure, ensuring that the app’s internal communication remains protected.

## Backend Structure with Actix

For the backend, I focused on two core features, each encapsulating key areas of functionality:

- **auth**: Handles all authentication-related processes, including signup, login, token management, account recovery, and 2FA (two-factor authentication).
- **profile**: Manages user profile settings, such as theme selection, language preferences, and password updates.

The Actix backend architecture is structured as follows:

```
├── backend
│   ├── .env
│   ├── .env.docker
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── Dockerfile
│   ├── configuration
│   │   ├── base.yaml
│   │   ├── docker.yaml
│   │   ├── local.yaml
│   │   └── production.yaml
│   ├── migrations
│   ├── src
│   │   ├── configuration.rs
│   │   ├── core
│   │   │   ├── constants
│   │   │   │   └── errors.rs
│   │   │   ├── helpers
│   │   │   │   └── mock_now.rs
│   │   │   ├── middlewares
│   │   │   │   └── token_validator.rs
│   │   │   ├── routes
│   │   │   │   └── health_check.rs
│   │   │   └── structs
│   │   │       └── responses.rs
│   │   ├── features
│   │   │   ├── auth
│   │   │   │   ├── helpers
│   │   │   │   │   ├── errors.rs
│   │   │   │   │   ├── password.rs
│   │   │   │   │   ├── token.rs
│   │   │   │   │   └── username.rs
│   │   │   │   ├── routes
│   │   │   │   │   ├── disable_otp.rs
│   │   │   │   │   ├── generate_otp.rs
│   │   │   │   │   ├── log_user_in.rs
│   │   │   │   │   ├── recover_account_using_2fa.rs
│   │   │   │   │   ├── recover_account_using_password.rs
│   │   │   │   │   ├── recover_account_without_2fa_enabled.rs
│   │   │   │   │   ├── signup.rs
│   │   │   │   │   ├── token.rs
│   │   │   │   │   ├── validate_otp.rs
│   │   │   │   │   └── verify_otp.rs
│   │   │   │   └── structs
│   │   │   │       ├── models.rs
│   │   │   │       ├── requests.rs
│   │   │   │       └── responses.rs
│   │   │   └── profile
│   │   │       ├── helpers
│   │   │       ├── routes
│   │   │       │   ├── get_profile_information.rs
│   │   │       │   ├── is_otp_enabled.rs
│   │   │       │   ├── post_profile_information.rs
│   │   │       │   ├── set_password.rs
│   │   │       │   └── update_password.rs
│   │   │       └── structs
│   │   │           ├── models.rs
│   │   │           ├── requests.rs
│   │   │           └── responses.rs
│   │   ├── lib.rs
│   │   ├── main.rs
│   │   └── startup.rs
│   └── tests
│       ├── auth
│       │   ├── login.rs
│       │   ├── otp.rs
│       │   ├── recovery
│       │   │   ├── recover_account_using_2fa.rs
│       │   │   ├── recover_account_using_password.rs
│       │   │   └── recover_account_without_2fa_enabled.rs
│       │   ├── signup.rs
│       │   └── token.rs
│       ├── core
│       │   └── health_check.rs
│       ├── helpers.rs
│       ├── mod.rs
│       └── profile
│           ├── profile.rs
│           ├── set_password.rs
│           └── update_password.rs
```

While this architecture may not be the absolute best, I found it straightforward to develop with, allowing for easy separation of concerns into small, purpose-driven files. This modular approach aids in maintaining readability and organization.

### Project Structure Overview

The **core** folder contains functionality that is not specific to any particular feature. While it’s currently minimal, I anticipate that it will become increasingly valuable as the project expands.

The **features/auth** folder is the largest at this stage, reflecting the complexity of the authentication process. For example, my signup route is organized as follows:

- The route itself is located in **features/auth/routes/signup.rs**.
- It uses a request body schema defined in **features/auth/structs/requests.rs**.
- The corresponding response body is defined in **features/auth/structs/responses.rs**.
- Helper functions for token generation are found in **features/auth/helpers/token.rs**.

### Application Startup Process

One interesting aspect of my implementation is the startup process. I primarily adapted methods from [zero2prod](https://www.lpalmieri.com/posts/2020-08-31-zero-to-production-3-5-html-forms-databases-integration-tests/#3-2-choosing-a-database-crate) with slight adjustments, allowing me to define and reuse an Actix app in both my tests and main.rs. This way, I can leverage Actix’s testing facilities without duplicating my route definitions. Here’s how I structured it:

- **src/startup.rs**:
  - **create_app**: This function returns an Actix App that includes my routes, CORS configuration, and other state variables. It’s utilized in my tests, eliminating the need to run a server for each one.
  - **run**: This function initializes an HTTP server running my app.
  - **Application** struct: This struct invokes run with a listener set to the address specified in my configuration.
- **src/main.rs**: This file retrieves the application configuration, creates an instance of **Application**, and runs it indefinitely.
- **src/configuration.rs**: Here, I define functions to read my application and database configurations.
- **configuration/base.yml**: This file contains my configuration settings. The base.yml file serves as the default when a variable is not specified in local.yml, docker.yml, or production.yml.

To utilize these configurations, I maintain a .env file in the backend/ directory:

```bash
APP_ENVIRONMENT=local # or docker or production
# And this so I can run sqlx command lines
DATABASE_URL=postgres://template_user:template_password@db:5432/template_db
```

## Frontend Structure with Flutter

Just like for my backend, I use these two **core** and **features** folders to organize my frontend:

```
└── frontend
    ├── .env
    ├── Dockerfile
    ├── assets
    │   ├── fonts
    │   └── images
    ├── l10n.yaml
    ├── lib
    │   ├── core
    │   │   ├── app.dart
    │   │   ├── messages
    │   │   │   ├── errors
    │   │   │   │   ├── data_error.dart
    │   │   │   │   └── domain_error.dart
    │   │   │   ├── message.dart
    │   │   │   └── message_mapper.dart
    │   │   ├── network
    │   │   │   ├── auth_interceptor.dart
    │   │   │   └── expired_token_retry_policy.dart
    │   │   ├── presentation
    │   │   │   └── screens
    │   │   │       ├── error_screen.dart
    │   │   │       └── root_screen.dart
    │   │   ├── router.dart
    │   │   ├── service_locator.dart
    │   │   ├── ui
    │   │   │   ├── colors.dart
    │   │   │   ├── extensions.dart
    │   │   │   ├── styles.dart
    │   │   │   ├── theme.dart
    │   │   │   ├── themes
    │   │   │   │   ├── dark.dart
    │   │   │   │   └── light.dart
    │   │   │   └── typography.dart
    │   │   ├── validators
    │   │   │   ├── password.dart
    │   │   │   └── username.dart
    │   │   └── widgets
    │   │       ├── app_logo.dart
    │   │       ├── custom_container.dart
    │   │       ├── custom_text_field.dart
    │   │       ├── global_snack_bar.dart
    │   │       └── icon_with_warning.dart
    │   ├── features
    │   │   ├── auth
    │   │   │   ├── data
    │   │   │   │   ├── errors
    │   │   │   │   │   └── data_error.dart
    │   │   │   │   ├── models
    │   │   │   │   │   ├── otp_model.dart
    │   │   │   │   │   ├── otp_request_model.dart
    │   │   │   │   │   ├── user_token_model.dart
    │   │   │   │   │   └── user_token_request_model.dart
    │   │   │   │   ├── repositories
    │   │   │   │   │   └── auth_repository_impl.dart
    │   │   │   │   ├── services
    │   │   │   │   │   └── auth_service.dart
    │   │   │   │   ├── sources
    │   │   │   │   │   └── remote_data_sources.dart
    │   │   │   │   └── storage
    │   │   │   │       └── token_storage.dart
    │   │   │   ├── domain
    │   │   │   │   ├── entities
    │   │   │   │   │   ├── otp_generation.dart
    │   │   │   │   │   └── user_token.dart
    │   │   │   │   ├── errors
    │   │   │   │   │   └── domain_error.dart
    │   │   │   │   ├── repositories
    │   │   │   │   │   └── auth_repository.dart
    │   │   │   │   └── usecases
    │   │   │   │       ├── check_if_account_has_two_factor_authentication_enabled_use_case.dart
    │   │   │   │       ├── disable_two_factor_authentication_use_case.dart
    │   │   │   │       ├── generate_two_factor_authentication_config_use_case.dart
    │   │   │   │       ├── login_usecase.dart
    │   │   │   │       ├── recover_account_with_two_factor_authentication_and_one_time_password_use_case.dart
    │   │   │   │       ├── recover_account_with_two_factor_authentication_and_password_use_case.dart
    │   │   │   │       ├── recover_account_without_two_factor_authentication_enabled_use_case.dart
    │   │   │   │       ├── signup_usecase.dart
    │   │   │   │       ├── validate_one_time_password_use_case.dart
    │   │   │   │       └── verify_one_time_password_use_case.dart
    │   │   │   └── presentation
    │   │   │       ├── blocs
    │   │   │       │   ├── auth
    │   │   │       │   │   ├── auth_bloc.dart
    │   │   │       │   │   ├── auth_events.dart
    │   │   │       │   │   └── auth_states.dart
    │   │   │       │   └── auth_login
    │   │   │       │       ├── auth_login_bloc.dart
    │   │   │       │       ├── auth_login_events.dart
    │   │   │       │       └── auth_login_states.dart
    │   │   │       ├── screens
    │   │   │       │   ├── login_screen.dart
    │   │   │       │   ├── recover_account_screen.dart
    │   │   │       │   ├── recovery_codes_screen.dart
    │   │   │       │   ├── signup_screen.dart
    │   │   │       │   └── unauthenticated_home_screen.dart
    │   │   │       └── widgets
    │   │   │           ├── background.dart
    │   │   │           └── successful_login_animation.dart
    │   │   ├── challenges
    │   │   │   ├── data
    │   │   │   ├── domain
    │   │   │   └── presentation
    │   │   │       └── challenges_screen.dart
    │   │   ├── habits
    │   │   │   ├── data
    │   │   │   ├── domain
    │   │   │   └── presentation
    │   │   │       └── habits_screen.dart
    │   │   ├── messages
    │   │   │   ├── data
    │   │   │   ├── domain
    │   │   │   └── presentation
    │   │   │       └── messages_screen.dart
    │   │   └── profile
    │   │       ├── data
    │   │       │   ├── errors
    │   │       │   │   └── data_error.dart
    │   │       │   ├── models
    │   │       │   │   ├── profile_model.dart
    │   │       │   │   └── profile_request_model.dart
    │   │       │   ├── repositories
    │   │       │   │   └── profile_repository_impl.dart
    │   │       │   └── sources
    │   │       │       └── remote_data_sources.dart
    │   │       ├── domain
    │   │       │   ├── entities
    │   │       │   │   └── profile.dart
    │   │       │   ├── errors
    │   │       │   │   └── domain_error.dart
    │   │       │   ├── repositories
    │   │       │   │   └── profile_repository.dart
    │   │       │   └── usecases
    │   │       │       ├── get_profile_usecase.dart
    │   │       │       ├── post_profile_usecase.dart
    │   │       │       ├── set_password_use_case.dart
    │   │       │       └── update_password_use_case.dart
    │   │       └── presentation
    │   │           ├── blocs
    │   │           │   ├── profile
    │   │           │   │   ├── profile_bloc.dart
    │   │           │   │   ├── profile_events.dart
    │   │           │   │   └── profile_states.dart
    │   │           │   ├── set_password
    │   │           │   │   ├── set_password_bloc.dart
    │   │           │   │   ├── set_password_events.dart
    │   │           │   │   └── set_password_states.dart
    │   │           │   └── update_password
    │   │           │       ├── update_password_bloc.dart
    │   │           │       ├── update_password_events.dart
    │   │           │       └── update_password_states.dart
    │   │           └── screens
    │   │               ├── about_screen.dart
    │   │               ├── language_selection_screen.dart
    │   │               ├── password_screen.dart
    │   │               ├── profile_screen.dart
    │   │               ├── theme_selection_screen.dart
    │   │               └── two_factor_authentication_screen.dart
    │   ├── l10n
    │   │   ├── app_en.arb
    │   │   └── app_fr.arb
    │   └── main.dart
    ├── pubspec.lock
    ├── pubspec.yaml
```

As you can see, I used an architecture like this for each feature:

```
name_of_the_feature
├── data
│   ├── errors
│   ├── models
│   ├── repositories
│   └── sources
├── domain
│   ├── entities
│   ├── errors
│   ├── repositories
│   └── usecases
└── presentation
│   ├── blocs
│   ├── screens
│   └── widgets
```

This architecture may seem complex at first glance, but my goal was to create a clean project where each file is small, logically organized, and easily testable. Here’s a breakdown of the structure:

### Project Structure Overview

- **data**: This folder contains the API logic:

  - **errors**: This subfolder holds all possible data errors that may arise within this feature.
  - **models**: These are the structures used for API requests and responses.
  - **repositories**: This contains the classes that implement the domain repositories.
  - **sources**: This includes the various methods to fulfill the repositories’ requirements.

    - Currently, the sources folder only contains remote source files, as the project primarily calls an external API. However, I anticipate needing local source files in the future for implementing a caching system.

- **domain**: This folder encapsulates the “business” logic:

  - **entities**: These are the structures necessary for my frontend logic.
  - **errors**: This subfolder contains all potential domain errors related to this feature.
  - **usecases**: These are functions designed to perform a single task.
  - **repositories**: This includes abstract classes that define the interfaces used in the business logic.

- **presentation**: This folder holds the logic for state management (using blocs), the actual views of the app (in screens), and reusable widgets:
  - Each bloc folder contains:
    - **events**: These represent the events emitted by screens or the bloc logic, signaling actions such as “I want to do this…” or “This just happened…”
    - **bloc**: This is where the state management logic is defined, encompassing use case calls, event listening, and state emissions.
    - **states**: This folder defines the possible states of the bloc, such as AuthAuthenticatedState or AuthUnauthenticatedState.

While I haven’t implemented tests for the frontend yet, this architecture is designed to facilitate testing, as everything is decomposed into small, manageable pieces.

### Testing Considerations

If you’re interested in testing this architecture, consider the following aspects:

1. Unit Tests:

- Test individual use cases in the domain layer to ensure that they perform their tasks correctly.
- Validate repositories to confirm they correctly implement their respective interfaces.
- Test models to ensure they correctly handle data serialization and deserialization.

2. Widget Tests:

- Verify that widgets render correctly with various states.
- Ensure that user interactions (e.g., button presses) trigger the appropriate events.

3. Integration Tests:

- Test the interaction between blocs and screens to confirm that events flow as expected.
- Validate that the presentation layer correctly communicates with the data layer.

### Environment Configuration

In the **frontend/** directory, I have an **.env** file with the following configuration:

```
API_BASE_URL=http://localhost:8000
# API_BASE_URL=http://192.168.1.166:8000 # if I need to deploy on my mobile for testing
```

## Conclusion

By combining Flutter, Rust, and Clean Architecture, I hope I laid the groundwork for a scalable, secure, and maintainable cross-platform app. As this project evolves, I may continue refining the architecture and adding new features in this template. Feel free to explore the project and adapt it for your own needs.

See you for the next article,
Thomas

[![Watch the video](/docs/screenshots/1.png)](https://youtu.be/ZCqYWs-lrRM)
