import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_states.dart';
import 'package:intl/intl.dart';

class DeviceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.devices),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileAuthenticated) {
            return _buildDeviceView(context, state);
          } else if (state is ProfileLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(
                child: Text(AppLocalizations.of(context)!.failedToLoadProfile));
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String deviceId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.confirmDeletion,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.confirmDeletionQuestion),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      BlocProvider.of<ProfileBloc>(context)
                          .add(DeleteDeviceEvent(deviceId: deviceId));
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.delete),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceView(BuildContext context, ProfileAuthenticated state) {
    if (state.devices.isNotEmpty) {
      return Column(
          children: state.devices.map((device) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 26, horizontal: 4),
          child: ListTile(
            title: Text(
              AppLocalizations.of(context)!.deviceInfo(
                device.parsedDeviceInfo.isMobile?.toString() ?? "null",
                device.parsedDeviceInfo.os ?? "null",
                device.parsedDeviceInfo.browser ?? "null",
                device.parsedDeviceInfo.model ?? "null",
              ),
            ),
            subtitle: Text(
              "${AppLocalizations.of(context)!.lastActivityDate} ${device.lastActivityDate != null ? DateFormat.yMMMMEEEEd(state.profile.locale).add_Hm().format(device.lastActivityDate!) : AppLocalizations.of(context)!.unknown}",
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, device.tokenId),
            ),
          ),
        );
      }).toList());
    } else {
      return Center(child: Text(AppLocalizations.of(context)!.noDevices));
    }
  }
}
