Available at: TODO

# Building a Cross-Platform App with Flutter and Rust: JWT & Session Deactivation

## Introduction

Welcome to the next article in my series on building a cross-platform app using Flutter for the frontend and Rust (via Actix) for the backend. In this article, I’ll share how I implemented efficient JWT validation and session deactivation mechanisms, tackling an important optimization that significantly improved the backend performance and enhanced the user experience.

For more context, you can start by reading [the first article](https://medium.com/@thomas.simmer/building-a-cross-platform-app-with-flutter-and-rust-a-beginners-journey-92cbb893c2f9) in this series, where I outlined the initial setup and my approach to combining these two powerful technologies.

A few weeks after releasing the initial version of this project, I began building a new application based on this template. It quickly became apparent that my authentication logic needed optimization. The middleware I originally wrote to validate JWTs decrypted the token and queried the database to match the user by performing a join operation on the users and user_tokens tables for every authenticated request. As you can imagine, this introduced significant overhead by hitting the database far too often—clearly, not ideal.

You might be wondering: Why was I saving JWT IDs in the database in the first place? After all, JWTs are designed to carry all the necessary information in a secure, self-contained format, and you typically don’t need to store them. However, I used a user_tokens table to enable session deactivation on specific devices. The catch? I hadn’t actually implemented the session deactivation feature, rendering the entire setup inefficient without serving its intended purpose.

This article is about fixing that oversight and implementing a robust mechanism for session deactivation while ensuring efficient JWT validation.

Here’s an improved version of your section:

## Optimizing JWT Validation

To address the inefficiencies in my initial approach, the new JWT validation mechanism now works as follows:

1. Extract Useful Properties from the JWT
   The middleware decodes the JWT to directly extract commonly used properties, such as user.id and user.is_admin. These are frequently required by routes, so extracting them upfront avoids redundant database queries.

2. Check for Revoked Tokens
   To ensure security, the middleware verifies that the JWT has not been revoked by querying the user_tokens table. This ensures sessions can still be deactivated when necessary.

3. Implement Token Caching
   To reduce database load, verified tokens are cached. This means the database is queried only if the JWT is not already in the cache.

4. Pass JWT Claims Through Requests
   Decoded claims from the JWT are passed along with the request context, making them easily accessible to downstream handlers.

Benefits of the New Approach:

• Reduced Database Queries: Instead of performing a database join for every authenticated request, the database is queried only when a JWT is missing from the cache and, the query is a simple 'SELECT'.
• Streamlined User Data Access: Routes that need full user data now perform a simple SELECT query on the users table using the user_id provided in the JWT claims, rather than relying on an expensive join operation.
• Enhanced Security & User Insights: The caching mechanism tracks the last activity for each token, allowing for better session monitoring and management.

Below is how I implemented the middleware:

```rust
pub struct TokenValidator {}

impl<S, B> Transform<S, ServiceRequest> for TokenValidator
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Transform = TokenValidatorMiddleware<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(TokenValidatorMiddleware {
            service: Rc::new(service),
        }))
    }
}

pub struct TokenValidatorMiddleware<S> {
    service: Rc<S>,
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

        let secret = req.app_data::<Data<String>>().unwrap().to_string();
        let pool = req.app_data::<Data<PgPool>>().unwrap().clone();
        let cached_tokens = req.app_data::<Data<TokenCache>>().unwrap().clone();

        Box::pin(async move {
            match retrieve_claims_for_token(req.request().clone(), secret) {
                Ok(claims) => {
                    if now() > DateTime::<Utc>::from_timestamp(claims.exp, 0).unwrap() {
                        return Ok(req.into_response(
                            HttpResponse::Unauthorized()
                                .json(AppError::AccessTokenExpired.to_response())
                                .map_into_right_body(),
                        ));
                    }

                    let last_activity_for_this_token =
                        cached_tokens.get_value_for_key(claims.jti).await;

                    match last_activity_for_this_token {
                        Some(last_activity) => {
                            // Update only if last activity is more than 5 minutes ago
                            // To not update too often
                            if now() - Duration::minutes(5) > last_activity {
                                cached_tokens.update_or_insert_key(claims.jti, now()).await;
                            }
                        }
                        None => {
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

                            // Check if token still exists (it could have been revoked)
                            let existing_token =
                                get_user_token(claims.user_id, claims.jti, &mut transaction).await;

                            match existing_token {
                                Ok(r) => {
                                    if r.is_none() {
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

                            cached_tokens.update_or_insert_key(claims.jti, now()).await;
                        }
                    }

                    // Store claims in request extensions
                    req.extensions_mut().insert(claims);
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

You can notice a cached_tokens state. It is a simple HashMap where:
• Key: The JWT ID.
• Value: The DateTime of the token’s last activity, allowing you to track user sessions on specific devices.

Here’s the implementation of the cached_tokens:

```rust

#[derive(Default)]
pub struct TokenCache {
    data: Arc<RwLock<HashMap<Uuid, DateTime<Utc>>>>,
}

impl TokenCache {
    pub async fn update_or_insert_key(&self, key: Uuid, value: DateTime<Utc>) {
        self.data
            .write()
            .await
            .entry(key)
            .and_modify(|v| *v = value)
            .or_insert(value);
    }

    pub async fn remove_key(&self, key: Uuid) {
        self.data.write().await.remove(&key);
    }

    pub async fn get_value_for_key(&self, key: Uuid) -> Option<DateTime<Utc>> {
        self.data.read().await.get(&key).cloned()
    }
}
```

This setup ensures efficient token validation while maintaining flexibility to manage session state securely.

## Session Deactivation

Session deactivation is an essential feature for any secure app, especially in scenarios like losing your phone or having it stolen. To enable users to log out of specific sessions, we first need a reliable way to identify each device connected to the server.

### Storing Device Information

Since each device corresponds to a unique JWT, we can store device-specific information in the user_tokens table alongside the JWT data. This enables us to provide detailed session information to users. However, building a multi-platform app introduces a challenge: identifying the device making the request. Unlike web-only apps where you can parse a standard User-Agent header, mobile and desktop apps require a custom approach.

### Using device_info_plus for Device Identification

Fortunately, the device_info_plus package in Flutter provides detailed information about the platform, OS version, model, and more. Using this package, I built a custom user agent string that contains essential details about the device in a structured format. Here’s the function that generates the custom user agent:

```dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_io/io.dart';

const String appVersion = '1.0.0';
String? _cachedUserAgent; // Private variable to store the cached result.

Future<String> getUserAgent() async {
  // Return the cached value if it exists.
  if (_cachedUserAgent != null) {
    return _cachedUserAgent!;
  }

  final deviceInfo = DeviceInfoPlugin();
  Map<String, dynamic> userAgentData = {
    'appVersion': appVersion,
    'os': Platform.operatingSystem,
    'isMobile': Platform.isAndroid || Platform.isIOS,
  };

  if (kIsWeb) {
    // Web-specific info
    final webInfo = await deviceInfo.webBrowserInfo;
    userAgentData['browser'] = webInfo.browserName.name;
  } else if (Platform.isAndroid) {
    // Android-specific info
    final androidInfo = await deviceInfo.androidInfo;
    userAgentData['model'] = androidInfo.model;
  } else if (Platform.isIOS) {
    // iOS-specific info
    final iosInfo = await deviceInfo.iosInfo;
    userAgentData['model'] = iosInfo.name;
  } else if (Platform.isMacOS) {
    // macOS-specific info
    final macosInfo = await deviceInfo.macOsInfo;
    userAgentData['model'] = macosInfo.model;
  }

  // Serialize the map to a JSON-like string for the User-Agent
  _cachedUserAgent = userAgentData.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('; ');

  return _cachedUserAgent!;
}
```

The result is a concise and easily parsable string that describes the device making the request.

### Sending the Custom User Agent

Since modifying the standard User-Agent header is restricted, I send the custom user agent in a new header: X-User-Agent. To process this header, you need to explicitly allow it in Actix’s CORS configuration. Here’s a snippet to enable it:

```rust
use actix_cors::Cors;

let cors = Cors::default()
.allowed_headers(vec![
        http::header::AUTHORIZATION,
        http::header::CONTENT_TYPE,
        http::header::HeaderName::from_static("x-user-agent"),
    ])
.allow_any_origin()
.max_age(3600);
```

### Saving Device Information

Whenever a user logs in, the backend parses the X-User-Agent header and saves the extracted device information in the user_tokens table along with the JWT ID. This makes it possible to display active sessions to the user, complete with details about each device.

### Session Management Endpoints

With device information stored in the user_tokens table, we need two endpoints to manage sessions:

1. Get Active Sessions: Returns a list of the user’s active sessions, including device details and the last activity timestamp.
2. Revoke a Session: Deletes a specific session (based on the token ID) from the user_tokens table.

I won’t go into the implementation details here, as it closely mirrors what I described in the previous article on locale selection. The key concepts and database interactions remain largely the same.

### User Experience

With these endpoints in place, users can view all active sessions in their account settings and revoke any session.

Below are screenshots of how the feature appears in the app:

<SCREENSHOTS>

If you’re interested in the implementation details, you can check out the code here.

Feel free to leave a comment if you have any questions or suggestions for improvement.

Thanks for reading, and see you in the next article, where I’ll probably share my new application!

Thomas
