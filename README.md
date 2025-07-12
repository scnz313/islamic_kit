# Islamic Kit for Flutter

[![pub version](https://img.shields.io/pub/v/islamic_kit?style=flat-square)](https://pub.dev/packages/islamic_kit)
[![pub points](https://img.shields.io/pub/points/islamic_kit?style=flat-square)](https://pub.dev/packages/islamic_kit/score)
[![likes](https://img.shields.io/pub/likes/islamic_kit?style=flat-square)](https://pub.dev/packages/islamic_kit/score)

A comprehensive Islamic toolkit for Flutter. This package provides essential widgets and services for Muslim-focused applications, including prayer times, a Qibla compass, a Hijri calendar, a Zakat calculator, and an Islamic events notifier.

It's designed to be simple, fully customizable, and easy to integrate into any Flutter project.

<img src="https://raw.githubusercontent.com/hashimhameem/islamic_kit/main/assets/screenshots/all_features.png" width="800"/>

## Features

- **Prayer Times Widget**: Displays daily prayer times based on the user's location.
- **Qibla Compass Widget**: An animated compass that points towards the Qibla.
- **Hijri Calendar Widget**: A simple and elegant widget to display the Hijri date.
- **Zakat Calculator Widget**: Helps users calculate their Zakat obligation.
- **Islamic Events Widget**: Lists important upcoming Islamic events and dates.
- **Core Services**: Location-aware services for accurate calculations and timezone handling.
- **Customizable UI**: All widgets are built to be easily themed and configured.

## Getting Started

### Prerequisites

This package requires location permissions to calculate prayer times and Qibla direction accurately. You must configure platform-specific location permissions for both Android and iOS.

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to provide accurate prayer times and Qibla direction.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location to provide accurate prayer times and Qibla direction.</string>
```

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  islamic_kit: ^0.1.0
```

Then, install packages from the command line:

```shell
flutter pub get
```

## Usage

Import the package and use the widgets directly in your build methods. All core features are exported from the main barrel file.

```dart
import 'package:islamic_kit/islamic_kit.dart';
```

### Prayer Times Widget

```dart
Scaffold(
  appBar: AppBar(title: const Text('Prayer Times')),
  body: const Center(
    child: PrayerTimeWidget(),
  ),
);
```

### Qibla Compass Widget

```dart
Scaffold(
  appBar: AppBar(title: const Text('Qibla Compass')),
  body: const Center(
    child: QiblaCompassWidget(),
  ),
);
```

### Hijri Calendar Widget

```dart
Scaffold(
  appBar: AppBar(title: const Text('Hijri Calendar')),
  body: const Center(
    child: HijriCalendarWidget(),
  ),
);
```

For a complete, runnable example, check out the `/example` directory in this repository.

## Additional Information

### Contributing

Contributions are welcome! If you have a feature request, bug report, or want to improve the code, please feel free to open a pull request or an issue on our [GitHub repository](https://github.com/hashimhameem/islamic_kit).

### License

This package is licensed under the MIT License. See the `LICENSE` file for details.
