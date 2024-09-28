import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_states.dart';
import 'package:go_router/go_router.dart';

class ErrorScreen extends StatelessWidget {
  final GoException? error;

  const ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      return Scaffold(
          appBar: AppBar(
            title: Row(children: [
              TextButton(
                  onPressed: () {
                    context.goNamed('home');
                  },
                  child: Row(children: [
                    Text('Flutter',
                        style: context.typographies.headingSmall
                            .copyWith(color: context.colors.background)),
                    Text(
                      'Actix',
                      style: context.typographies.headingSmall
                          .copyWith(color: context.colors.hint),
                    ),
                  ])),
              Spacer(),
              if (state is AuthAuthenticatedState)
                ElevatedButton(
                  onPressed: () {
                    BlocProvider.of<AuthBloc>(context).add(AuthLogoutEvent());
                  },
                  child: Text(AppLocalizations.of(context)!.logout),
                ),
            ]),
            backgroundColor: context.colors.primary,
          ),
          body: Center(
            child: Text(error != null
                ? error.toString()
                : AppLocalizations.of(context)!.defaultError),
          ));
    });
  }
}
