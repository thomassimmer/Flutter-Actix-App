# Response mapping

| Status code | Backend code                                  | Data error                                   | Domain error                                       |
| ----------- | --------------------------------------------- | -------------------------------------------- | -------------------------------------------------- |
| 200         | OTP_DISABLED                                  |                                              |                                                    |
| 200         | OTP_GENERATED                                 |                                              |                                                    |
| 200         | OTP_STATUS                                    |                                              |                                                    |
| 200         | OTP_VERIFIED                                  |                                              |                                                    |
| 200         | PASSWORD_CHANGED                              |                                              |                                                    |
| 200         | PROFILE_FETCHED                               |                                              |                                                    |
| 200         | PROFILE_UPDATED                               |                                              |                                                    |
| 200         | TOKEN_REFRESHED                               |                                              |                                                    |
| 200         | SERVER_IS_RUNNING                             |                                              |                                                    |
| 200         | USER_LOGGED_IN_WITHOUT_OTP                    |                                              |                                                    |
| 200         | USER_LOGGED_IN_AFTER_ACCOUNT_RECOVERY         |                                              |                                                    |
| 200         | USER_LOGGED_IN_AFTER_OTP_VALIDATION           |                                              |                                                    |
| 200         | USER_LOGS_IN_WITH_OTP_ENABLED                 |                                              |                                                    |
| 201         | USER_SIGNED_UP                                |                                              |                                                    |
| 401         | ACCESS_TOKEN_EXPIRED                          |                                              |                                                    |
| 401         | INVALID_ACCESS_TOKEN                          |                                              |                                                    |
| 401         | INVALID_REFRESH_TOKEN                         | InvalidRefreshTokenError                     | InvalidRefreshTokenDomainError                     |
| 401         | INVALID_USERNAME_OR_CODE_OR_RECOVERY_CODE     | InvalidUsernameOrCodeOrRecoveryCodeError     | InvalidUsernameOrCodeOrRecoveryCodeDomainError     |
| 401         | INVALID_USERNAME_OR_PASSWORD                  | InvalidUsernameOrPasswordError               | InvalidUsernameOrPasswordDomainError               |
| 401         | INVALID_USERNAME_OR_PASSWORD_OR_RECOVERY_CODE | InvalidUsernameOrPasswordOrRecoveryCodeError | InvalidUsernameOrPasswordOrRecoveryCodeDomainError |
| 401         | INVALID_USERNAME_OR_RECOVERY_CODE             | InvalidUsernameOrRecoveryCodeError           | InvalidUsernameOrRecoveryCodeDomainError           |
| 401         | REFRESH_TOKEN_EXPIRED                         | RefreshTokenExpiredError                     | RefreshTokenExpiredDomainError                     |
| 401         | PASSWORD_TOO_SHORT                            | PasswordTooShortError                        | PasswordTooShortError                              |
| 401         | PASSWORD_TOO_WEAK                             | PasswordNotComplexEnoughError                | PasswordNotComplexEnoughError                      |
| 401         | USERNAME_NOT_RESPECTING_RULES                 | UsernameNotRespectingRulesError              | UsernameNotRespectingRulesError                    |
| 401         | USERNAME_WRONG_SIZE                           | UsernameWrongSizeError                       | UsernameWrongSizeError                             |
| 403         | PASSWORD_MUST_BE_CHANGED                      | PasswordMustBeChangedError                   | PasswordMustBeChangedDomainError                   |
| 403         | PASSWORD_NOT_EXPIRED                          | PasswordNotExpiredError                      | PasswordNotExpiredDomainError                      |
| 403         | TWO_FACTOR_AUTHENTICATION_NOT_ENABLED         | TwoFactorAuthenticationNotEnabledError       | TwoFactorAuthenticationNotEnabledDomainError       |
| 404         | USER_NOT_FOUND                                | UserNotFoundError                            | UserNotFoundDomainError                            |
| 409         | USER_ALREADY_EXISTS                           | UserAlreadyExistingError                     | UserAlreadyExistingDomainError                     |
| 500         | DATABASE_CONNECTION                           | InternalServerError                          | InternalServerDomainError                          |
| 500         | DATABASE_QUERY                                | InternalServerError                          | InternalServerDomainError                          |
| 500         | DATABASE_TRANSACTION                          | InternalServerError                          | InternalServerDomainError                          |
| 500         | PASSWORD_HASH                                 | InternalServerError                          | InternalServerDomainError                          |
| 500         | RECOVERY_CODE_HASH                            | InternalServerError                          | InternalServerDomainError                          |
| 500         | TOKEN_GENERATION                              | InternalServerError                          | InternalServerDomainError                          |
| 500         | USER_INSERT                                   | InternalServerError                          | InternalServerDomainError                          |
| 500         | USER_TOKEN_DELETION                           | InternalServerError                          | InternalServerDomainError                          |
| 500         | USER_UPDATE                                   | InternalServerError                          | InternalServerDomainError                          |
