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
