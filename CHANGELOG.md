## 0.2.0

* **FEAT**: Added richer Islamic event metadata, upcoming-event highlights, and detailed event sheets.
* **FEAT**: Added reminder scheduling helpers with deterministic notification IDs and better scheduling feedback.
* **FEAT**: Added Hijri calendar improvements including a Today shortcut, legend, and monthly event summary.
* **FEAT**: Added a clearer Zakat calculation summary and an explicit "No Zakat Due" zero-state.
* **FEAT**: Added enhanced Qibla guidance with compass fallbacks, bearing instructions, and cardinal direction hints.
* **IMPROVEMENT**: Improved Prayer Times UX with cached location lookups, manual refresh, Hijri date display, and safer countdown refresh logic.
* **IMPROVEMENT**: Improved location permission recovery across Prayer Times and Qibla features with settings shortcuts and clearer errors.
* **IMPROVEMENT**: Modernized the example app theme and improved reminder testing flows.
* **FIX**: Corrected Qibla asset usage to avoid runtime failures caused by missing packaged assets.
* **FIX**: Prevented reminders from claiming success when scheduling fails or the reminder time has already passed.
* **FIX**: Replaced a placeholder package test with meaningful coverage and added unit tests for Qibla and event helpers.

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
