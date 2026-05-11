# HayFeeder iPhone App

Small native iPhone app for the STM32 HayFeeder BLE controller.

## What It Does

- Scans only for the BLE device named `HayFeeder`.
- Connects to the existing HayFeeder custom BLE characteristic.
- Sends the iPhone time automatically after connecting.
- Edits the three daily feed times using `KL HH:MM` fields.
- Shows the next feed time.
- Sends `S` when disconnecting so the feeder returns to low-power sleep.
- Shows one feeder photo at the bottom, chosen randomly when the app opens.

## BLE Commands

The app writes UTF-8 commands to:

- Service UUID: `0000fe40-cc7a-482a-984a-7f2ed5b3e58f`
- Characteristic UUID: `0000fe41-8e22-4541-9d4c-21edae82ed19`

Commands:

```text
T:14:32:05
F:14:00,19:00,23:00
S
```

## Open In Xcode

1. Copy/open this folder on a Mac:

```text
C:\Users\Nikolai\Documents\New project\HayFeederIOS
```

2. Open:

```text
HayFeederIOS.xcodeproj
```

3. Select your iPhone as the run target.
4. In Xcode, set your Apple development team under **Signing & Capabilities**.
5. Press Run.

Before connecting, enable BLE setup mode on the feeder by opening/closing the reload switch twice within 10 seconds.
