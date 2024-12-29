class ParsedDeviceInfo {
  bool? isMobile;
  String? os;
  String? browser;
  String? appVersion;
  String? model;

  ParsedDeviceInfo({
    required this.isMobile,
    required this.os,
    required this.browser,
    required this.appVersion,
    required this.model,
  });
}

class Device {
  String tokenId;
  ParsedDeviceInfo parsedDeviceInfo;
  DateTime? lastActivityDate;

  Device({
    required this.tokenId,
    required this.parsedDeviceInfo,
    required this.lastActivityDate,
  });
}
