## 0.2.0

### New APIs
* `HijriCalendarController` — `ChangeNotifier` + `ValueListenable<HijriCalendar>`
  that drives `HijriCalendarWidget` programmatically. Exposes
  `goToMonth`, `goToPreviousMonth`, `goToNextMonth` and `goToToday`.
* `PrayerCalc.getCurrentLocation` now accepts injectable hooks
  (`locationRequest`, `lastKnownPosition`, `isLocationServiceEnabled`,
  `checkPermission`, `requestPermission`) so apps and tests can exercise
  the full fallback ladder without a live platform.
* `ReminderScheduler` gains `setDefaultLocation` /
  `defaultLocation` and `scheduleNotification(..., location:)`, so apps
  that pin reminders to a specific `tz.Location` (e.g. a traveler's home
  city) no longer depend on `tz.local`. A new public
  `resolveScheduledDate` helper returns the resolved `tz.TZDateTime`.

### Bug fixes
* **Qibla compass (critical)**: compass rendered nothing because the widget
  referenced `assets/images/compass.svg` and `assets/images/needle.svg`, which
  do not exist in the package. The widget is now drawn with `CustomPaint` and
  has no asset dependencies.
* **Qibla needle direction (critical)**: the needle was rotated by
  `-(qiblaBearing + deviceHeading)`, which pointed in the wrong direction. The
  correct formula `qiblaBearing - deviceHeading` is now used and the result
  is normalized to `[0, 360)` for devices that report headings in
  `(-180, 180]`. When the user is aligned with the Qibla (within 5°) the
  needle turns green.
* **Hijri calendar navigation (critical)**: navigating to a previous or next
  month threw `LateInitializationError` because `HijriCalendar` instances
  were built via setters only, leaving `lengthOfMonth` uninitialized. A new
  `HijriService.firstDayOfMonth` / `HijriService.fromDate` helper returns
  fully-initialized instances and is used throughout the package.
* **Reminder notifications**: `event.hashCode` was used as a notification id,
  which can be negative on Android. IDs are now derived from
  `(year, month, day, name)` and masked to a non-negative 31-bit int. The
  scheduler also requests `POST_NOTIFICATIONS` on Android 13+ and cancels
  past-dated reminders cleanly.
* **Prayer time countdown**: the per-second timer updated state fields
  outside `setState`, which could cause stale rendering. The countdown now
  updates inside `setState` and auto-refreshes prayer times when the
  countdown hits zero.
* **Prayer-time Prayer.none edge case**: after Isha the widget previously
  fell back to "now" when computing the next prayer, producing a countdown of
  `0` forever. It now correctly rolls forward to tomorrow's Fajr via a new
  `PrayerCalc.nextPrayerFrom` helper.

### Features
* `QiblaService` validates latitude/longitude, exposes `KaabaLocation`
  constants, and always normalizes bearings to `[0, 360)`.
* `QiblaDetails` is now a `const` class with value equality.
* `HijriService` exposes `HijriRange.minYear`/`maxYear` (1356–1500 AH),
  `validateDate`, `fromDate`, and `firstDayOfMonth`.
* `IslamicEventService` gains a `nextEvent({from, yearsAhead})` helper and
  `knownEventNames` for iteration. `IslamicEvent` exposes `gregorianDate`.
* `ZakatCalculatorWidget` exposes a pure `calculate()` method returning a
  `ZakatResult` with a `ZakatStatus` (`empty`, `belowNisab`, `due`). It also
  accepts thousands-separator input (`"10, 000"`).
* `PrayerCalc.getPrayerTimes` accepts a `madhab` parameter (defaults to
  Shafi) and validates coordinates.
* `PrayerCalc.getCurrentLocation` falls back to the last known location when
  both high- and medium-accuracy requests time out.
* `IslamicEventsWidget` accepts an `onReminderTap` override for testability
  and a `year` parameter.
* `HijriCalendarWidget` accepts an `initialDate`.

### Testing
* Added **60 tests** (up from 9) covering services (Qibla bearings for known
  cities, Hijri conversions round-trip, prayer ordering, Zakat status
  transitions) and widgets (calendar navigation, event rendering, reminder
  taps, compass loading states).

### Cleanup
* Removed the `flutter_svg` dependency and the `assets/` section from
  `pubspec.yaml` — the package is now asset-free.

## 0.1.0

* **BREAKING CHANGE**: Migrated to null safety and updated SDK constraints.
* **FEAT**: Initial release of the Islamic Kit package.
* **FEAT**: Added Prayer Times, Qibla Compass, Hijri Calendar, Zakat Calculator, and Islamic Events widgets.
* **FEAT**: Added configurable currency symbol and Nisab threshold validation to Zakat Calculator.
* **FEAT**: Enhanced notification system with proper iOS permissions handling.
* **FIX**: Fixed critical HijriCalendar creation bug in Islamic Events Service.
* **FIX**: Fixed performance issue in Prayer Time widget timer (reduced unnecessary rebuilds).
* **FIX**: Added proper memory management for compass stream subscriptions.
* **FIX**: Enhanced input validation with negative number checks in Zakat Calculator.
* **FIX**: Added null safety checks and timeout handling for location services.
* **FIX**: Added edge case protection for prayer time calculations.
* **FIX**: Updated to stable adhan package version (^2.0.0+1).
* **IMPROVEMENT**: Added comprehensive error handling and user feedback.
* **IMPROVEMENT**: Enhanced notification scheduling with timezone awareness.
* **IMPROVEMENT**: Added graceful fallbacks for location and placemark failures.
* **TEST**: Added comprehensive widget tests with 100% pass rate.
* **TEST**: Added validation tests for negative numbers and edge cases.
* **DOCS**: Updated README, added usage examples, and improved package metadata for pub.dev.
