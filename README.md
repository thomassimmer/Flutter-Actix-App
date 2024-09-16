## Docker images

To pull the right flutter image: https://github.com/cirruslabs/docker-images-flutter/pkgs/container/flutter

For mac:
docker pull ghcr.io/cirruslabs/flutter:3.24.0-0.2.pre@sha256:8e6ae5d10c653665cbe5f5737e23eb9ef50eaa6d2a0b90d834226db1352fa007

## Backend commands

### To be able to use sqlx cli tools

```bash
cargo install sqlx-cli --no-default-features --features postgres
```

#### To create a new migration file

```bash
sqlx migrate add name_of_your_migration
sqlx migrate run
```

## Run locally on external device

Change every occurence of 192.168. somewhere in the code to match your IP.

Create frontend/.env on the model of frontend/.env.template changing the variable to match your situation (API_BASE_URL for instance).

## Run on Android :

Make sure to follow the section ## Run locally on external device first.

Turn on Developer Options and USB debugging “File sharing”.

Developer Options > Select USB Configuration > Change it from “File Transfer” (default option) to Charging”.

The phone will ask if you want to always allow USB debugging from this device.

Say yes.

Install android-studio from their web page.

Create a fake project.

From android-studio, Settings -> SDK Manager -> Languages & Frameworks -> Android SDK -> SDK Tools

Check Android SDK Command-line tools box.

Click Apply.

To check everything is fine: flutter doctor --verbose

To build the apk: flutter build apk --flavor dev --release

To install on device: flutter install --flavor dev

# Sources of inspiration

Install localizations on ios : https://medium.com/@gauravswarankar/internationalizing-flutter-apps-a2b82e804ca6
Flutter, blocs, clean architecture : https://github.com/Yoga3911/flutter_bloc_clean_architecture/tree/master