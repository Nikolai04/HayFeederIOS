# HayFeeder iPhone App

Native SwiftUI iPhone app for the STM32 HayFeeder BLE controller.

## Features

- Scans only for the BLE device named `HayFeeder`.
- Connects to the HayFeeder custom BLE characteristic.
- Syncs the iPhone time automatically after connecting.
- Edits three daily feed times with `KL HH:MM` fields.
- Shows the next feed time and refreshes it while the app is open.
- Sends `S` on disconnect so the controller exits BLE setup mode and returns to sleep.
- Shows one feeder photo at the bottom, chosen randomly each time the app opens.

## Requirements

- iPhone with BLE support
- Feeder firmware advertising as `HayFeeder`

## Build From Windows

GitHub Actions builds the native SwiftUI app on a hosted macOS runner. No Mac
is needed locally.

1. Push the project to the `HayFeederIOS` GitHub repository.
2. Open the repository's **Actions** tab.
3. Select **Build iPhone App**, then choose **Run workflow**.
4. Open the completed run and download `HayFeederIOS-unsigned-IPA`.
5. Extract the downloaded artifact ZIP to get the `.ipa` file.
6. Sign and install the IPA from Windows using
   [AltStore/AltServer](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows).

The GitHub artifact is intentionally unsigned because Apple signing is tied to
an Apple account and device. AltStore performs that signing while installing.
With a free Apple account the app normally needs refreshing every seven days.
A paid Apple Developer account permits longer-lived signing.

The workflow also runs automatically whenever iPhone app code is pushed. A
failed run uploads `HayFeederIOS-build-log` for troubleshooting.

## Run From Xcode

For local Mac development:

1. Open `HayFeederIOS.xcodeproj` in Xcode.
2. Select the `HayFeederIOS` target.
3. Set your Apple development team under **Signing & Capabilities**.
4. Select an iPhone as the run target.
5. Press **Run**.

## BLE Protocol

The app writes UTF-8 commands to:

- Service UUID: `0000fe40-cc7a-482a-984a-7f2ed5b3e58f`
- Characteristic UUID: `0000fe41-8e22-4541-9d4c-21edae82ed19`

Commands:

```text
T:14:32:05
F:14:00,19:00,23:00
S
```

The feeder reports details on its serial console. The app does not require BLE notifications.

Before connecting, enable BLE setup mode on the feeder by opening/closing the reload switch twice within 10 seconds. The feeder keeps BLE setup mode active for 10 minutes.

Only one phone/app can connect to the feeder at a time. Disconnect nRF Connect, ST BLE Toolbox, or any other BLE app before scanning from HayFeeder.
