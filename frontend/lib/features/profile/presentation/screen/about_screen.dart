import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Uri githubUrl = Uri.parse('https://github.com/thomassimmer');

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.about),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(children: [
                        Text(
                          AppLocalizations.of(context)!.aboutText,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        TextButton(
                          onPressed: () async {
                            if (await canLaunchUrl(githubUrl)) {
                              await launchUrl(githubUrl);
                            } else {
                              throw 'Could not launch $githubUrl';
                            }
                          },
                          child: Image.asset(
                            'assets/github-logo.png',
                            width: 50,
                            height: 50,
                          ),
                        ),
                      ])))
            ])));
  }
}