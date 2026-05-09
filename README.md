# Islamic Kit for Flutter

[![pub version](https://img.shields.io/pub/v/islamic_kit?style=flat-square)](https://pub.dev/packages/islamic_kit)
[![pub points](https://img.shields.io/pub/points/islamic_kit?style=flat-square)](https://pub.dev/packages/islamic_kit/score)
[![likes](https://img.shields.io/pub/likes/islamic_kit?style=flat-square)](https://pub.dev/packages/islamic_kit/score)

A comprehensive Islamic toolkit for Flutter. This package provides essential widgets and services for Muslim-focused applications, including prayer times, a Qibla compass, a Hijri calendar, a Zakat calculator, and an Islamic events notifier.

It's designed to be simple, fully customizable, and easy to integrate into any Flutter project. The entire UI is drawn in code — the package has **zero asset dependencies**.

## Features

- **Prayer Times Widget** — daily prayer times based on the user's location, with a live countdown to the next prayer and a selectable calculation method / madhab.
- **Qibla Compass Widget** — `CustomPaint`-based compass that points towards the Kaaba, with graceful fallbacks for web and devices without a compass sensor.
- **Hijri Calendar Widget** — month view with today highlighting, event dot markers, and programmatic navigation via `HijriCalendarController`.
- **Zakat Calculator Widget** — multi-asset input, configurable currency and Nisab threshold, plus a pure `ZakatCalculatorWidget.calculate()` helper.
- **Islamic Events Widget** — scrollable list of major annual events with a "Set reminder" action backed by `ReminderScheduler`.
- **Core services** — `PrayerCalc`, `QiblaService`, `HijriService`, `IslamicEventService`, `ReminderScheduler`, `IslamicDateConverter`.

## Getting Started

### Prerequisites

This package requires location permissions to calculate prayer times and Qibla direction accurately. You must configure platform-specific location permissions for both Android and iOS.

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<!-- Needed only if you use ReminderScheduler on Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
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
  islamic_kit: ^0.2.0
```

Then, install packages from the command line:

```shell
flutter pub get
```

## Usage

Import the package and use the widgets directly in your build methods. All public API is exported from the main barrel file.

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

Drive the calendar from anywhere in the widget tree via `HijriCalendarController`:

```dart
final controller = HijriCalendarController();

Scaffold(
  appBar: AppBar(
    title: const Text('Hijri Calendar'),
    actions: [
      IconButton(
        icon: const Icon(Icons.today),
        tooltip: 'Go to today',
        onPressed: controller.goToToday,
      ),
    ],
  ),
  body: HijriCalendarWidget(controller: controller),
);
```

### Zakat Calculator

Use the widget for a drop-in UI, or call the pure helper directly:

```dart
final result = ZakatCalculatorWidget.calculate(
  cash: 10_000,
  gold: 20_000,
  debts: 5_000,
);
print(result.status);    // ZakatStatus.due
print(result.zakatDue);  // 625.0  (2.5% of 25,000)
```

### Islamic events & reminders

```dart
await ReminderScheduler.initialize();
await ReminderScheduler.requestPermissions();

final next = IslamicEventService.nextEvent();
if (next != null) {
  await ReminderScheduler.scheduleNotification(next);
}
```

For a complete, runnable example, check out the [`/example`](./example) directory.

## Additional Information

### Contributing

Contributions are welcome! If you have a feature request, bug report, or want to improve the code, please feel free to open a pull request or an issue on our [GitHub repository](https://github.com/scnz313/islamic_kit).

### License

This package is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

### Contact

Maintainer: **trashbin2605@gmail.com** · [GitHub issues](https://github.com/scnz313/islamic_kit/issues)
