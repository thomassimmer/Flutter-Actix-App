# Building a Flutter / Rust app: Architecture

## Context

This article explains my project architecture to build a Flutter/Rust app with:

- a first page where you can login / signup using a username and a password (no email because my user shouldn't be personally identifiable)
- a second page where freshly registered users can see their recovery codes
- a third page where freshly registered user can enable 2-factor authentication (2FA) with one-time passwords (OTP) using an external app like Google's Authenticator
- a fourth page that is a typical app view with four tabs using a common base screen with a logout button
- a fifth page for the profile tab where people can change their languages, theme and enable/disable 2FA

Don't hesitate to read the first article of this serie to get more context, [](here).

## Docker containers

I used docker to make sure my app will work whatever the platforms it runs on. For this project, I used three docker containers orchestrated by a docker-compose.yml file:

- a frontend container, running a flutter web app
- a backend container, running a Actix API
- a database container, running a PostgreSQL database

My global architecture looks roughly like this:

.
├── backend
│   ├── Cargo.toml
│   ├── Dockerfile
│ ├── .env
│   ├── migrations
│   ├── src
│   │   ├── lib.rs
│   │   ├── main.rs
│   ├── ...
├── db
│   └── Dockerfile
│ └── .env
├── docker-compose.yml
├── frontend
│ ├── Dockerfile
│ ├── .env
│ ├── lib
│ │   └── main.dart
│ ├── pubspec.yaml
│   ├── ...
└── ...

My docker-compose.yml file contains:

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

As you can see, I am using a bridge network to make sure only my containers can access each other locally and no other container that may exist on the machine.

## Backend architecture

In this project, I identified two main features:

- **auth**, for everything related to authentication
- **profile**, for everything related to user profiles

Therefore, my Actix architecture is like so:

backend
├── Cargo.toml
├── Dockerfile
├── configuration
│   ├── base.yaml
│   ├── docker.yaml
│   ├── local.yaml
│   └── production.yaml
├── migrations
│   ├── ...
├── src
│   ├── configuration.rs
│   ├── core
│   │   ├── helpers
│   │   │   └── mock_now.rs
│   │   ├── routes
│   │   │   └── health_check.rs
│   │   └── structs
│   │   └── responses.rs
│   ├── features
│   │   ├── auth
│   │   │   ├── helpers
│   │   │   │   ├── errors.rs
│   │   │   │   └── token.rs
│   │   │   ├── routes
│   │   │   │   ├── login.rs
│   │   │   │   ├── otp.rs
│   │   │   │   ├── signup.rs
│   │   │   │   └── token.rs
│   │   │   └── structs
│   │   │   ├── models.rs
│   │   │   ├── requests.rs
│   │   │   └── responses.rs
│   │   └── profile
│   │   ├── routes
│   │   │   └── profile.rs
│   │   └── structs
│   │   ├── models.rs
│   │   ├── requests.rs
│   │   └── responses.rs
│   ├── lib.rs
│   ├── main.rs
│   └── startup.rs
└── tests
├── auth
│   ├── login.rs
│   ├── otp.rs
│   ├── signup.rs
│   └── token.rs
├── core
│   └── health_check.rs
├── helpers.rs
├── mod.rs
└── profile
└── profile.rs

It may not be the best, but I found this architecture easy to develop with as you can easily separate things in different small files that have a self-describing location based on their purpose.

The **core** folder is for everything that is not really specific to a feature. It's not big for now, but you can imagine it will be useful later.
The **features/auth** is the biggest folder for now because the authentication requires a lot of code. For instance, my signup route is located in **features/auth/routes/signup.rs**, uses a request body schema defined in **features/auth/structs/requests.rs**, returns a response body defined in **features/auth/structs/responses.rs** and, uses helpers located in **features/auth/helpers/token.rs** to generate tokens.

One interesting thing here is the start process. I essentially took what zero2prod did with small ajustments so that I could define and reuse an Actix app in my tests and in my main.rs and, use the Actix's tests facilities without writing my routes twice. For this, I have:

- **src/startup.rs**, where I define:
  - a function **create_app** that returns an Actix's App containing my routes, my cors config and other state variable
    -> This function is used in my test so I don't have to run a server for each of them, but use Actix's testing facilities instead.
  - a function **run** that creates a http server running my App
  - a struct **Application** that calls **run** with a listener at the adress written in my config
- **src/main.rs**, where I get my configuration, create an Application and run it indefinitely
- **src/configuration.rs**, where I define functions to read my application and database configurations
- **configuration/base.yml**, where I define my configurations, basis being used by default when a variable is not written in local.yml, docker.yml or production.yml.

To use one of these configurations, I have this **.env** file:

```bash
APP_ENVIRONMENT=local # or docker or production
# And this so I can run sqlx command lines
DATABASE_URL=postgres://template_user:template_password@db:5432/template_db
```

## Frontend architecture

Just like for my backend, I will use these two **features** folder to organize my frontend:

frontend
├── Dockerfile
├── l10n.yaml
├── lib
│   ├── core
│   │   ├── constants
│   │   │   ├── app_colors.dart
│   │   │   └── errors.dart
│   │   ├── network
│   │   │   └── auth_interceptor.dart
│   │   ├── presentation
│   │   │   └── root_screen.dart
│   │   ├── service_locator.dart
│   │   ├── themes
│   │   │   └── app_theme.dart
│   │   └── widgets
│   │   └── custom_tab_bar.dart
│   ├── features
│   │   ├── auth
│   │   │   ├── data
│   │   │   │   ├── models
│   │   │   │   │   ├── otp_generation_model.dart
│   │   │   │   │   ├── user_token_model.dart
│   │   │   │   │   └── user_token_request_model.dart
│   │   │   │   ├── repositories
│   │   │   │   │   └── auth_repository_impl.dart
│   │   │   │   ├── services
│   │   │   │   │   └── auth_service.dart
│   │   │   │   ├── sources
│   │   │   │   │   └── remote_data_sources.dart
│   │   │   │   └── storage
│   │   │   │   └── token_storage.dart
│   │   │   ├── domain
│   │   │   │   ├── entities
│   │   │   │   │   ├── otp_generation.dart
│   │   │   │   │   └── user_token.dart
│   │   │   │   ├── errors
│   │   │   │   │   └── failures.dart
│   │   │   │   ├── repositories
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases
│   │   │   │   ├── disable_otp_use_case.dart
│   │   │   │   ├── generate_otp_config_use_case.dart
│   │   │   │   ├── login_usecase.dart
│   │   │   │   ├── signup_usecase.dart
│   │   │   │   ├── validate_otp_usecase.dart
│   │   │   │   └── verify_otp_usecase.dart
│   │   │   └── presentation
│   │   │   ├── bloc
│   │   │   │   ├── auth_bloc.dart
│   │   │   │   ├── auth_events.dart
│   │   │   │   └── auth_states.dart
│   │   │   ├── screens
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── recovery_codes_screen.dart
│   │   │   │   ├── signup_screen.dart
│   │   │   │   └── unauthenticated_home_screen.dart
│   │   │   ├── widgets
│   │   │   │   ├── background.dart
│   │   │   │   ├── button.dart
│   │   │   │   ├── custom_text_field.dart
│   │   │   │   └── submit_button.dart
│   │   ├── challenges
│   │   │   └── presentation
│   │   │   └── challenges_screen.dart
│   │   ├── habits
│   │   │   └── presentation
│   │   │   └── habits_screen.dart
│   │   ├── messages
│   │   │   └── presentation
│   │   │   └── messages_screen.dart
│   │   └── profile
│   │   ├── data
│   │   │   ├── models
│   │   │   │   ├── user_model.dart
│   │   │   │   └── user_request_model.dart
│   │   │   ├── repositories
│   │   │   │   └── profile_repository_impl.dart
│   │   │   └── sources
│   │   │   └── remote_data_sources.dart
│   │   ├── domain
│   │   │   ├── entities
│   │   │   │   └── user.dart
│   │   │   ├── errors
│   │   │   │   └── failures.dart
│   │   │   ├── repositories
│   │   │   │   └── profile_repository.dart
│   │   │   └── usecases
│   │   │   ├── get_profile_usecase.dart
│   │   │   └── post_profile_usecase.dart
│   │   └── presentation
│   │   ├── bloc
│   │   │   ├── profile_bloc.dart
│   │   │   ├── profile_events.dart
│   │   │   └── profile_states.dart
│   │   └── screen
│   │   ├── language_selection_screen.dart
│   │   ├── profile_screen.dart
│   │   └── theme_selection_screen.dart
│   ├── l10n
│   │   ├── app_en.arb
│   │   └── app_fr.arb
│   └── main.dart
├── pubspec.yaml

As you can see, I used a schema like this for each feature:

name_of_the_feature
├── data
│   ├── models
│   ├── repositories
│   └── sources
├── domain
│   ├── entities
│   ├── errors
│   ├── repositories
│   └── usecases
└── presentation
├── bloc
└── screen

This may look overcomplicated but have in mind that I wanted a clean project where every file stays small, located at an expected location and every piece of my program can be easily unit tested:

- **data** holds the API logic:

  - **models** are the structures for API requests and responses

  - **repositories** are the classes that implement the **business repositories**

  - **sources** are the possible ways to effectively do what the repositories need

    - In **sources**, I have only **remote sources** files for now, because the project is simply calling an external API, but in the future, I could have to implement a caching system and I would need **local sources** files for that.

- **domain** holds the "business" logic:

  - **entities** are the structures I actually need for my frontend logic

  - **errors** holds all the possible errors thay may arise for this feature

  - **usecases** are functions doing one thing only and

  - **repositories** are abstract classes that describe the interfaces used my business logic.

- **presentation** holds the logic for state management (**blocs**) and **screens**, which are the actual views of the app.

  - Each **bloc** folder contains:

    - **events** which are the event emitted by screens or the bloc logic to say "Hey I want to do this..." or "Hey this happened..."

    - **bloc** which is where the state management logic is defined; where we call usecases, listen for events and emit others...

    - **states** which are the possible states we can be for this bloc; for instance, you can be in AuthAuthenticated state or AuthUnauthenticated

I didn't write tests yet for the frontend, but this architecture should allow it easily because every things is decomposed into small pieces.

And that's it for this architecture presentation, I hope it was helpful and inspired you! If you have any critics and questions, don't hesitate!

See you for the next article,
Thomas
