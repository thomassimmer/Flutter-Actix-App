Available at: https://medium.com/@thomas.simmer/building-a-cross-platform-app-with-flutter-and-rust-locale-selection-1fb318224129

# Building a Cross-Platform App with Flutter and Rust: Locale Selection

## Introduction

In this article, I’ll walk you through how I implemented locale selection for a cross-platform app using Flutter for the frontend and Actix for the backend. We’ll cover everything from the screen where the locale is selected to the process of updating the application’s locale, including interactions with the API.

For more context, feel free to check out [the first article](https://medium.com/@thomas.simmer/building-a-cross-platform-app-with-flutter-and-rust-a-beginners-journey-92cbb893c2f9) of this series.

## 1. How is the locale selected in Flutter?

First things first, where is the locale defined in the app? Let’s start with the app’s entry point in **main.dart**:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  setupServiceLocator();
  runApp(FlutterActixApp());
}
```

Next, let’s take a look at **FlutterActixApp** in **core/app.dart**:

```dart
class FlutterActixApp extends StatelessWidget {
  const FlutterActixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: _createBlocProviders(),
        child:
            BlocBuilder<ProfileBloc, ProfileState>(builder: (context, state) {
          Locale locale =
              Locale(Platform.localeName); // device locale by default

          final Brightness brightness =
              MediaQuery.of(context).platformBrightness;
          ThemeData themeData = brightness == Brightness.dark
              ? DarkAppTheme().themeData
              : LightAppTheme().themeData;

          if (state.profile != null) {
            locale = Locale(state.profile!.locale);
            themeData = state.profile!.theme == 'dark'
                ? DarkAppTheme().themeData
                : LightAppTheme().themeData;
          }

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            locale: locale,
            theme: themeData,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        }));
  }

  ...
}
```

As you can see, the app initially uses the device’s locale and theme. However, if a profile exists (i.e., if the user is authenticated), it retrieves the saved locale and theme from the user’s profile.

PS: This FlutterActixApp class also defines the method **\_createBlocProviders**, which initializes the blocs.

## 2. From selecting a locale to calling the API

Let’s now look at the screen where the user can select a different locale, in **features/profile/presentation/screens/language_selection_screen.dart**:

```dart
class LocaleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileAuthenticated) {
            return _buildLocaleSelectionView(context, state);
          } else if (state is ProfileLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(
                child: Text(AppLocalizations.of(context)!.failedToLoadProfile));
          }
        },
      ),
    );
  }

  Widget _buildLocaleSelectionView(
      BuildContext context, ProfileAuthenticated state) {
    final List<Map<String, String>> locales = [
      {'code': 'en', 'name': 'English'},
      {'code': 'fr', 'name': 'Français'},
    ];

    return Column(
        children: locales.map((locale) {
      return ListTile(
        title: Text(locale['name']!),
        leading: Radio<String>(
          value: locale['code']!,
          groupValue: state.profile.locale,
          onChanged: (String? value) {
            BlocProvider.of<ProfileBloc>(context)
                .add(ProfileUpdateLocaleEvent(locale: value!));
          },
        ),
      );
    }).toList());
  }
}
```

This screen provides a simple interface for selecting the language:

![Locale selection screen](/docs/screenshots/10.png)

In case you’re wondering about the blue header and navigation bar, it’s because this screen is a child of **RootScreen**, defined in **core/presentation/screens/root_screen.dart**. Feel free to explore it in **core/router.dart** to see how it’s used.

So, when the user selects a locale, it triggers an event with:

```dart
BlocProvider.of<ProfileBloc>(context)
            .add(ProfileUpdateLocaleEvent(locale: value!));
```

The event is defined in **features/profile/presentation/blocs/profile_events.dart**:

```dart
class ProfileUpdateLocaleEvent extends ProfileEvent {
  final String locale;

  const ProfileUpdateLocaleEvent({
    required this.locale,
  });

  @override
  List<Object> get props => [locale];
}
```

This event is handled by the **ProfileBloc**:

```dart
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ...
  final PostProfileUsecase postProfileUsecase =
      GetIt.instance<PostProfileUsecase>();
  ...

  ProfileBloc({required this.authBloc}) : super(ProfileLoading()) {
    ...
    on<ProfileUpdateLocaleEvent>(_updateLocale);
    ...

    Future<void> _updateLocale(
      ProfileUpdateLocaleEvent event, Emitter<ProfileState> emit) async {
        final currentState = state as ProfileAuthenticated;

        emit(ProfileLoading(profile: state.profile));

        Profile profile = currentState.profile;
        profile.locale = event.locale;

        final result = await postProfileUsecase.call(profile);

        result.fold((error) {
        if (error is ShouldLogoutError) {
            authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
        } else {
            emit(ProfileAuthenticated(
            profile: currentState.profile,
            message: ErrorMessage(error.messageKey),
            ));
        }
        },
            (profile) => emit(ProfileAuthenticated(
                profile: profile,
                message: SuccessMessage('profileUpdateSuccessful'))));
    }
    ...
  }
}
```

When a user selects a locale, the app emits a **ProfileLoading** state, keeping the current profile data (locale, theme, etc.). It then calls the responsible use case. Depending on the outcome, it either emits a **ProfileAuthenticated** state with updated information or an error/success message, or disconnects the user if a **ShouldLogoutError** occurs.

The **postProfileUsecase.call(profile)** method is straightforward:

```dart
class PostProfileUsecase {
  final ProfileRepository profileRepository;

  PostProfileUsecase(this.profileRepository);

  Future<Either<DomainError, Profile>> call(Profile profile) async {
    return await profileRepository.postProfileInformation(profile);
  }
}
```

This could include additional validations, but for now, it simply forwards the request to the profile repository’s **postProfileInformation** method.

The **ProfileRepository** interface is defined in **features/profile/domain/repositories/profile_repository.dart**:

```dart
abstract class ProfileRepository {
  ...
  Future<Either<DomainError, Profile>> postProfileInformation(Profile profile);
  ...
}
```

Its implementation is in **features/profile/data/repositories/profile_repository_impl.dart**:

```dart
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final logger = Logger();

  ProfileRepositoryImpl(this.remoteDataSource);

  ...
  @override
  Future<Either<DomainError, Profile>> postProfileInformation(
      Profile profile) async {
    try {
      final profileModel = await remoteDataSource.postProfileInformation(
          UpdateProfileRequestModel(
              username: profile.username,
              locale: profile.locale,
              theme: profile.theme));

      return Right(Profile(
          username: profileModel.username,
          locale: profileModel.locale,
          theme: profileModel.theme,
          otpBase32: profileModel.otpBase32,
          otpAuthUrl: profileModel.otpAuthUrl,
          otpVerified: profileModel.otpVerified,
          passwordIsExpired: profileModel.passwordIsExpired));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      return Left(InvalidRefreshTokenDomainError());
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      return Left(RefreshTokenNotFoundDomainError());
    } on RefreshTokenExpiredError {
      logger.e('RefreshTokenExpiredError occured.');
      return Left(RefreshTokenExpiredDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }
  ...
}
```

This method calls **remoteDataSource** to make the API request via **postProfileInformation**, which passes the request model **UpdateProfileRequestModel**. Depending on the outcome, the function either returns the updated profile or logs and converts any data errors into domain errors.

Now, let’s take a look at **ProfileRemoteDataSource**, located in **features/profile/data/sources/remote_data_sources.dart**:

```dart
class ProfileRemoteDataSource {
  final InterceptedClient apiClient;
  final String baseUrl;

  ProfileRemoteDataSource({required this.apiClient, required this.baseUrl});
  ...
  Future<ProfileModel> postProfileInformation(
      UpdateProfileRequestModel profile) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(profile.toJson()),
    );

    final jsonBody = json.decode(response.body);

    if (response.statusCode == 200) {
      try {
        return ProfileModel.fromJson(jsonBody['user']);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      throw UnauthorizedError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }
  ...
}
```

I am using an instance of **InterceptedClient** to pass in the access token and retry the request if it gets expired. This way, the client can refresh it and retry the operation seamlessly.

Once the request is made, I attempt to decode the response. If decoding fails, I raise a **ParsingError** from the data layer. If the request returns a different status code, I handle it accordingly by throwing the corresponding error.

## 3. On the backend side

The entry point of the API is the **src/main.rs** file, where an instance of **Application** is created. This initializes a server running the result of the **create_app** function:

```rust
pub fn create_app(
    configuration: &Settings,
) -> App<
    impl ServiceFactory<
        ServiceRequest,
        Config = (),
        Response = ServiceResponse<impl MessageBody>,
        Error = Error,
        InitError = (),
    >,
> {
    let connection_pool = get_connection_pool(&configuration.database);
    let secret = &configuration.application.secret;
    ...
    App::new()
        .service(
            web::scope("/api")
                ...
                .service(
                    web::scope("/users")
                        // Scope without middleware applied to routes that don't need it
                        .service(is_otp_enabled)
                        // Nested scope with middleware for protected routes
                        .service(
                            web::scope("")
                                .wrap(TokenValidator::new(
                                    secret.to_string(),
                                    connection_pool.clone(),
                                ))
                                .service(get_profile_information)
                                .service(post_profile_information)
                                ...
                        ),
                ),
        )
        ...
        .app_data(web::Data::new(connection_pool.clone()))
        .app_data(web::Data::new(secret.clone()))
}
```

This function sets up the routes and state variables for the API. The **post_profile_information** service is located in **features/profile/routes/post_profile_information.rs** and handles updating user profile data:

```rust
#[post("/me")]
pub async fn post_profile_information(
    body: web::Json<UserUpdateRequest>,
    pool: web::Data<PgPool>,
    mut request_user: User,
) -> impl Responder {
    let mut transaction = match pool.begin().await {
        Ok(t) => t,
        Err(_) => {
            return HttpResponse::InternalServerError()
                .json(AppError::DatabaseConnection.to_response())
        }
    };

    request_user.username = body.username.clone();
    request_user.locale = body.locale.clone();
    request_user.theme = body.theme.clone();

    let updated_user_result = sqlx::query!(
        r#"
        UPDATE users
        SET username = $1, locale = $2, theme = $3
        WHERE id = $4
        "#,
        request_user.username,
        request_user.locale,
        request_user.theme,
        request_user.id
    )
    .fetch_optional(&mut *transaction)
    .await;

    if (transaction.commit().await).is_err() {
        return HttpResponse::InternalServerError()
            .json(AppError::DatabaseTransaction.to_response());
    }

    match updated_user_result {
        Ok(_) => HttpResponse::Ok().json(UserResponse {
            code: "PROFILE_UPDATED".to_string(),
            user: request_user.to_user_data(),
        }),
        Err(_) => HttpResponse::InternalServerError().json(AppError::UserUpdate.to_response()),
    }
}
```

The process here is fairly straightforward. First, I obtain a connection from the pool of available connections. Then, I construct a query to update the relevant user in the database. Based on the query’s outcome, I return either a success response or an error with a meaningful status code.

You might be wondering how this parameter made its way into my function:

```rust
mut request_user: User
```

This is made possible by the **TokenValidatorMiddleware**, which extracts the access token from the request, retrieves the associated user, or rejects the request with an error if necessary. The middleware is defined in **core/middlewares/token_validator.rs**. Here’s the essential part of it:

```rust
pub struct TokenValidatorMiddleware<S> {
    service: Rc<S>,
    secret: Rc<String>,
    pool: Rc<PgPool>,
}

impl<S, B> Service<ServiceRequest> for TokenValidatorMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = Rc::clone(&self.service);
        let secret = Rc::clone(&self.secret);
        let pool = Rc::clone(&self.pool);

        Box::pin(async move {
            match retrieve_claims_for_token(req.request().clone(), secret.to_string()) {
                Ok(claims) => {
                    if now() > DateTime::<Utc>::from_timestamp(claims.exp, 0).unwrap() {
                        return Ok(req.into_response(
                            HttpResponse::Unauthorized()
                                .json(AppError::AccessTokenExpired.to_response())
                                .map_into_right_body(),
                        ));
                    }

                    let mut transaction = match pool.begin().await {
                        Ok(t) => t,
                        Err(_) => {
                            return Ok(req.into_response(
                                HttpResponse::InternalServerError()
                                    .json(AppError::DatabaseConnection.to_response())
                                    .map_into_right_body(),
                            ));
                        }
                    };


                    let existing_user = sqlx::query_as!(
                        User,
                        r#"
                        SELECT u.*
                        FROM users u
                        JOIN user_tokens ut ON u.id = ut.user_id
                        WHERE ut.token_id = $1
                        "#,
                        claims.jti,
                    )
                    .fetch_optional(&mut *transaction)
                    .await;

                    let user = match existing_user {
                        Ok(existing_user) => {
                            if let Some(user) = existing_user {
                                user
                            } else {
                                return Ok(req.into_response(
                                    HttpResponse::Unauthorized()
                                        .json(AppError::InvalidAccessToken.to_response())
                                        .map_into_right_body(),
                                ));
                            }
                        }
                        Err(_) => {
                            return Ok(req.into_response(
                                HttpResponse::InternalServerError()
                                    .json(AppError::DatabaseQuery.to_response())
                                    .map_into_right_body(),
                            ));
                        }
                    };

                    // Store user in request extensions
                    req.extensions_mut().insert(user);
                    let res = service.call(req).await?;
                    Ok(res.map_into_left_body())
                }
                Err(_) => Ok(req.into_response(
                    HttpResponse::Unauthorized()
                        .json(AppError::InvalidAccessToken.to_response())
                        .map_into_right_body(),
                )),
            }
        })
    }
}
```

In essence, the middleware validates the token, retrieves the user, and attaches it to the request. If the token is invalid, expired, or any other error occurs, a descriptive error response like **InvalidAccessToken** or **AccessTokenExpired** is returned.

## 4. Where and how do I write my translations in Flutter?

Now that we’ve covered how the locale is updated both on the backend and in the frontend, let’s take a look at how this locale is used to handle translations in the app.

You may have already noticed from the earlier code snippets that I often use something like this:

```dart
appBar: AppBar(
  title: Text(AppLocalizations.of(context)!.selectLanguage),
),
```

In this case, Flutter retrieves the corresponding entry from **lib/l10n/app_en.arb** if the locale is set to **“en”**, or from **lib/l10n/app_fr.arb** if the locale is **“fr”**. These files look like:

```json
{
  "@@locale": "en",
  "alreadyAnAccountLogin": "Already have an account? Sign in",
  "about": "About",
  ...
}
```

But how do I handle translations for dynamic error and success messages? I found a neat solution by creating a **GlobalSnackBar** component:

```dart
class GlobalSnackBar {
  static Color _getBackgroundColor(BuildContext context, Message message) {
    if (message is SuccessMessage) {
      return context.colors.accent;
    } else if (message is InfoMessage) {
      return context.colors.information;
    } else {
      return context.colors.error;
    }
  }

  static show(
    BuildContext context,
    Message? message,
  ) {
    if (message == null) {
      return null;
    }

    final messageTranslated = getTranslatedMessage(context, message);
    final backgroundColor = _getBackgroundColor(context, message);

    return (ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messageTranslated),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        closeIconColor: context.colors.text,
      ),
    ));
  }
}
```

I can then call this component inside my screens like this:

```dart
...
@override
Widget build(BuildContext context) {
  return BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
      GlobalSnackBar.show(context, state.message);
    }
    ...
  )
}
```

This way, I can customize the appearance of the snack bar based on the type of message (error, success, info) and easily translate the message using **getTranslatedMessage**, which is defined in **core/messages/message_mapper.dart**:

```dart
String getTranslatedMessage(BuildContext context, Message message) {
  final localizations = AppLocalizations.of(context)!;

  if (message is ErrorMessage) {
    switch (message.messageKey) {
      // Generic
      case 'unknown_error':
        return localizations.unknownError;
      ...

      // Auth
      case 'invalidUsernameOrCodeOrRecoveryCodeError':
        return localizations.invalidUsernameOrCodeOrRecoveryCodeError;
      ...

      // Profile
      case 'passwordNotExpiredError':
        return localizations.passwordNotExpiredError;
      ...
    }
  } else if (message is SuccessMessage) {
    switch (message.messageKey) {
      // Auth
      case 'loginSuccessful':
        return localizations.loginSuccessful;
      ...

      // Profile
      case 'passwordUpdateSuccessful':
        return localizations.passwordUpdateSuccessful;
      ...
    }
  } else if (message is InfoMessage) {
    switch (message.messageKey) {
      // Auth
      case 'recoveryCodesCopied':
        return localizations.recoveryCodesCopied;
      ...
    }
  } else {
    return localizations.defaultError;
  }
}
```

While this solution works well, having all the messages in a single file isn’t the cleanest approach. If you have any suggestions for improvement, I’d love to hear them!

And that wraps up this article! I hope it provided some clarity. Feel free to reach out if you have any questions or need further details on this project.

Thanks for reading,
Thomas
