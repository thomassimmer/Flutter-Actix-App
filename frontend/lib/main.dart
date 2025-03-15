import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutteractixapp/core/app.dart';
import 'package:flutteractixapp/core/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  setupServiceLocator();
  runApp(FlutterActixApp());
}
