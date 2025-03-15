import 'package:equatable/equatable.dart';

class ParsedDeviceInfoModel extends Equatable {
  final bool? isMobile;
  final String? os;
  final String? browser;
  final String? appVersion;
  final String? model;

  const ParsedDeviceInfoModel({
    required this.isMobile,
    required this.os,
    required this.browser,
    required this.appVersion,
    required this.model,
  });

  factory ParsedDeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return ParsedDeviceInfoModel(
      isMobile: json['is_mobile'] as bool?,
      os: json['os'] as String?,
      browser: json['browser'] as String?,
      appVersion: json['app_version'] as String?,
      model: json['model'] as String?,
    );
  }

  @override
  List<Object?> get props => [isMobile, os, browser, appVersion, model];
}

class DeviceModel extends Equatable {
  final String tokenId;
  final ParsedDeviceInfoModel parsedDeviceInfoModel;
  final DateTime? lastActivityDate;

  const DeviceModel({
    required this.tokenId,
    required this.parsedDeviceInfoModel,
    required this.lastActivityDate,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      tokenId: json['token_id'] as String? ?? '',
      parsedDeviceInfoModel: json['parsed_device_info'] is Map<String, dynamic>
          ? ParsedDeviceInfoModel.fromJson(json['parsed_device_info'])
          : const ParsedDeviceInfoModel(
              isMobile: null,
              os: null,
              browser: null,
              appVersion: null,
              model: null,
            ),
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.tryParse(json['last_activity_date'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [tokenId, parsedDeviceInfoModel, lastActivityDate];
}
