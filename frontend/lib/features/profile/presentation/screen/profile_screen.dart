import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:reallystick/features/profile/presentation/screen/language_selection_screen%20copy.dart';
import 'package:reallystick/features/profile/presentation/screen/theme_selection_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileSettings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.language),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LocaleSelectionScreen()),
              );
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.theme),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ThemeSelectionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
