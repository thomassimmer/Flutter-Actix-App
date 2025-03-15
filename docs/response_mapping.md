# Response mapping

| Status code | Backend code                                  | Data error | Domain error | Message displayed |
| ----------- | --------------------------------------------- | ---------- | ------------ | ----------------- |
| 200         | OTP_DISABLED                                  |            |              |                   |
| 200         | OTP_GENERATED                                 |            |              |                   |
| 200         | OTP_STATUS                                    |            |              |                   |
| 200         | OTP_VERIFIED                                  |            |              |                   |
| 200         | PASSWORD_CHANGED                              |            |              |                   |
| 200         | PROFILE_FETCHED                               |            |              |                   |
| 200         | PROFILE_UPDATED                               |            |              |                   |
| 200         | TOKEN_REFRESHED                               |            |              |                   |
| 200         | SERVER_IS_RUNNING                             |            |              |                   |
| 200         | USER_LOGGED_IN_WITHOUT_OTP                    |            |              |                   |
| 200         | USER_LOGGED_IN_AFTER_ACCOUNT_RECOVERY         |            |              |                   |
| 200         | USER_LOGGED_IN_AFTER_OTP_VALIDATION           |            |              |                   |
| 200         | USER_LOGS_IN_WITH_OTP_ENABLED                 |            |              |                   |
| 201         | USER_SIGNED_UP                                |            |              |                   |
| 401         | ACCESS_TOKEN_EXPIRED                          |            |              |                   |
| 401         | REFRESH_TOKEN_EXPIRED                         |            |              |                   |
| 401         | INVALID_ACCESS_TOKEN                          |            |              |                   |
| 401         | INVALID_REFRESH_TOKEN                         |            |              |                   |
| 401         | INVALID_USERNAME_OR_CODE_OR_RECOVERY_CODE     |            |              |                   |
| 401         | INVALID_USERNAME_OR_PASSWORD                  |            |              |                   |
| 401         | INVALID_USERNAME_OR_PASSWORD_OR_RECOVERY_CODE |            |              |                   |
| 401         | INVALID_USERNAME_OR_RECOVERY_CODE             |            |              |                   |
| 403         | PASSWORD_MUST_BE_CHANGED                      |            |              |                   |
| 403         | PASSWORD_NOT_EXPIRED                          |            |              |                   |
| 403         | TWO_FACTOR_AUTHENTICATION_NOT_ENABLED         |            |              |                   |
| 404         | USER_NOT_FOUND                                |            |              |                   |
| 409         | USER_ALREADY_EXISTS                           |            |              |                   |
| 500         | DATABASE_CONNECTION                           |            |              |                   |
| 500         | DATABASE_QUERY                                |            |              |                   |
| 500         | DATABASE_TRANSACTION                          |            |              |                   |
| 500         | PASSWORD_HASH                                 |            |              |                   |
| 500         | RECOVERY_CODE_HASH                            |            |              |                   |
| 500         | TOKEN_GENERATION                              |            |              |                   |
| 500         | USER_INSERT                                   |            |              |                   |
| 500         | USER_TOKEN_DELETION                           |            |              |                   |
| 500         | USER_UPDATE                                   |            |              |                   |
