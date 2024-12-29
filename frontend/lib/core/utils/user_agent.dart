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
