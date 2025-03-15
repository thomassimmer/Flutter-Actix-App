import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutteractixapp/core/network/auth_interceptor.dart';
import 'package:flutteractixapp/core/network/expired_token_retry_policy.dart';
import 'package:flutteractixapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutteractixapp/features/auth/data/services/auth_service.dart';
import 'package:flutteractixapp/features/auth/data/sources/remote_data_sources.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/check_if_otp_enabled_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/disable_otp_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/generate_otp_config_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_with_recovery_code_and_otp_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_with_recovery_code_and_password_usecase%20copy.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_with_recovery_code_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/signup_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/validate_otp_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:flutteractixapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutteractixapp/features/profile/data/sources/remote_data_sources.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/post_profile_usecase.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/set_password_use_case.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/update_password_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:http_interceptor/http_interceptor.dart';

final sl = GetIt.instance;

void setup_service_locator() {
  final baseUrl = '${dotenv.env['API_BASE_URL']}/api';
  final tokenStorage = TokenStorage();
  final authService = AuthService(baseUrl: baseUrl, tokenStorage: tokenStorage);

  final apiClient = InterceptedClient.build(
    interceptors: [
      AuthInterceptor(baseUrl: baseUrl, tokenStorage: tokenStorage)
    ],
    requestTimeout: Duration(seconds: 15),
    retryPolicy: ExpiredTokenRetryPolicy(authService: authService),
  );

  // Remote Data Sources
  sl.registerSingleton<AuthRemoteDataSource>(
      AuthRemoteDataSource(apiClient: apiClient, baseUrl: baseUrl));
  sl.registerSingleton<ProfileRemoteDataSource>(
      ProfileRemoteDataSource(apiClient: apiClient, baseUrl: baseUrl));

  // Repositories
  sl.registerSingleton<AuthRepository>(
      AuthRepositoryImpl(sl<AuthRemoteDataSource>()));
  sl.registerSingleton<ProfileRepository>(
      ProfileRepositoryImpl(sl<ProfileRemoteDataSource>()));

  // Use cases
  sl.registerSingleton<LoginUseCase>(LoginUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignupUseCase>(SignupUseCase(sl<AuthRepository>()));
  sl.registerSingleton<VerifyOtpUseCase>(
      VerifyOtpUseCase(sl<AuthRepository>()));
  sl.registerSingleton<ValidateOtpUsecase>(
      ValidateOtpUsecase(sl<AuthRepository>()));
  sl.registerSingleton<GenerateOtpConfigUseCase>(
      GenerateOtpConfigUseCase(sl<AuthRepository>()));
  sl.registerSingleton<DisableOtpUseCase>(
      DisableOtpUseCase(sl<AuthRepository>()));
  sl.registerSingleton<CheckIfOtpEnabledUsecase>(
      CheckIfOtpEnabledUsecase(sl<AuthRepository>()));
  sl.registerSingleton<RecoverAccountWithRecoveryCodeAndPasswordUseCase>(
      RecoverAccountWithRecoveryCodeAndPasswordUseCase(sl<AuthRepository>()));
  sl.registerSingleton<RecoverAccountWithRecoveryCodeAndOtpUseCase>(
      RecoverAccountWithRecoveryCodeAndOtpUseCase(sl<AuthRepository>()));
  sl.registerSingleton<RecoverAccountWithRecoveryCodeUseCase>(
      RecoverAccountWithRecoveryCodeUseCase(sl<AuthRepository>()));
  sl.registerSingleton<GetProfileUsecase>(
      GetProfileUsecase(sl<ProfileRepository>()));
  sl.registerSingleton<PostProfileUsecase>(
      PostProfileUsecase(sl<ProfileRepository>()));
  sl.registerSingleton<SetPasswordUseCase>(
      SetPasswordUseCase(sl<ProfileRepository>()));
  sl.registerSingleton<UpdatePasswordUseCase>(
      UpdatePasswordUseCase(sl<ProfileRepository>()));
}
