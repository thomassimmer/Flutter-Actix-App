import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:reallystick/core/network/auth_interceptor.dart';
import 'package:reallystick/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:reallystick/features/auth/data/services/auth_service.dart';
import 'package:reallystick/features/auth/data/sources/remote_data_sources.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';
import 'package:reallystick/features/auth/domain/usecases/disable_otp_use_case.dart';
import 'package:reallystick/features/auth/domain/usecases/generate_otp_config_use_case.dart';
import 'package:reallystick/features/auth/domain/usecases/login_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/signup_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/validate_otp_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:reallystick/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:reallystick/features/profile/data/sources/remote_data_sources.dart';
import 'package:reallystick/features/profile/domain/repositories/profile_repository.dart';
import 'package:reallystick/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:reallystick/features/profile/domain/usecases/post_profile_usecase.dart';

final sl = GetIt.instance;

void setup() {
  final baseUrl = '${dotenv.env['API_BASE_URL']}/api';
  final tokenStorage = TokenStorage();
  final authService = AuthService(baseUrl: baseUrl, tokenStorage: tokenStorage);

  final apiClient = InterceptedClient.build(
    interceptors: [
      AuthInterceptor(
          baseUrl: baseUrl,
          authService: authService,
          tokenStorage: tokenStorage)
    ],
    requestTimeout: Duration(seconds: 15),
  );

  // Remote Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(apiClient: apiClient, baseUrl: baseUrl));
  sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSource(apiClient: apiClient, baseUrl: baseUrl));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()));
  sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl<ProfileRemoteDataSource>()));

  // Use cases
  sl.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<SignupUseCase>(
      () => SignupUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<VerifyOtpUseCase>(
      () => VerifyOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<ValidateOtpUsecase>(
      () => ValidateOtpUsecase(sl<AuthRepository>()));
  sl.registerLazySingleton<GenerateOtpConfigUseCase>(
      () => GenerateOtpConfigUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<DisableOtpUseCase>(
      () => DisableOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<GetProfileUsecase>(
      () => GetProfileUsecase(sl<ProfileRepository>()));
  sl.registerLazySingleton<PostProfileUsecase>(
      () => PostProfileUsecase(sl<ProfileRepository>()));
}
