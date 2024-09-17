import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/router.dart';
import 'package:flutteractixapp/core/themes/app_theme.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_login/auth_login_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_states.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/set_password/set_password_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/update_password/update_password_bloc.dart';
import 'package:universal_io/io.dart';

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
              ? AppTheme.darkTheme
              : AppTheme.lightTheme;

          if (state.profile != null) {
            locale = Locale(state.profile!.locale);
            themeData = state.profile!.theme == 'dark'
                ? AppTheme.darkTheme
                : AppTheme.lightTheme;
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

  List<BlocProvider> _createBlocProviders() {
    final authBloc = AuthBloc();
    final authSignupFormBloc = AuthSignupFormBloc();
    final profileBloc = ProfileBloc(authBloc: authBloc);
    final profileSetPasswordFormBloc = ProfileSetPasswordFormBloc();
    final profileUpdatePasswordFormBloc = ProfileUpdatePasswordFormBloc();

    authBloc.add(AuthInitializeEvent());

    return [
      BlocProvider<AuthSignupFormBloc>(
        create: (context) => authSignupFormBloc,
      ),
      BlocProvider<AuthBloc>(
        create: (context) => authBloc,
      ),
      BlocProvider<ProfileBloc>(
        create: (context) => profileBloc,
      ),
      BlocProvider<ProfileSetPasswordFormBloc>(
        create: (context) => profileSetPasswordFormBloc,
      ),
      BlocProvider<ProfileUpdatePasswordFormBloc>(
        create: (context) => profileUpdatePasswordFormBloc,
      ),
    ];
  }
}
