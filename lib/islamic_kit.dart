// Islamic Kit – Barrel export file
//
// Re-export the package’s public API so that applications can simply:
//   import 'package:islamic_kit/islamic_kit.dart';
// and access all widgets & services.
// Widgets
export 'src/prayer_time/prayer_time_widget.dart';
export 'src/hijri_calendar/hijri_calendar_widget.dart';
export 'src/qibla/qibla_compass_widget.dart';
export 'src/events/islamic_events_widget.dart';
export 'src/zakat/zakat_calculator_widget.dart';

// Services & utilities
export 'src/prayer_time/prayer_calc.dart';
export 'src/qibla/qibla_service.dart';
export 'src/hijri_calendar/hijri_service.dart';
export 'src/date_converter/converter.dart';
export 'src/events/islamic_event_service.dart';
export 'src/events/reminder_scheduler.dart';

// Third-party models that callers are expected to use
export 'package:hijri/hijri_calendar.dart';

