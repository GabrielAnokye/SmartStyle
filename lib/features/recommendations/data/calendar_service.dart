import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstyle/features/recommendations/domain/recommendation_context.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) => CalendarService());

class CalendarService {
  final DeviceCalendarPlugin _plugin;
  CalendarService({DeviceCalendarPlugin? plugin}) : _plugin = plugin ?? DeviceCalendarPlugin();

  /// Scans today's events and infers an Occasion from keywords in titles/locations.
  /// Returns null if permission denied, no matching events, or calendars unavailable.
  /// All access is on-device; nothing is persisted or transmitted.
  Future<Occasion?> inferOccasion(DateTime when) async {
    try {
      final perm = await _plugin.hasPermissions();
      if (perm.data != true) {
        final req = await _plugin.requestPermissions();
        if (req.data != true) return null;
      }

      final cals = await _plugin.retrieveCalendars();
      final ids = cals.data?.map((c) => c.id).whereType<String>().toList() ?? [];
      if (ids.isEmpty) return null;

      final start = DateTime(when.year, when.month, when.day);
      final end = start.add(const Duration(days: 1));
      final params = RetrieveEventsParams(startDate: start, endDate: end);

      final titles = <String>[];
      for (final id in ids) {
        final res = await _plugin.retrieveEvents(id, params);
        final events = res.data;
        if (events == null) continue;
        for (final e in events) {
          final buf = StringBuffer();
          if (e.title != null) buf.write(e.title);
          if (e.location != null) buf..write(' ')..write(e.location);
          if (e.description != null) buf..write(' ')..write(e.description);
          titles.add(buf.toString().toLowerCase());
        }
      }

      return _classify(titles);
    } catch (_) {
      // Calendar plugins are notoriously fragile across OS upgrades; a surfaced
      // error shouldn't block the dashboard — we simply skip the hint.
      return null;
    }
  }

  /// Higher-priority matches win (formal beats work beats workout beats outdoors beats casual).
  Occasion? _classify(List<String> haystack) {
    if (haystack.isEmpty) return null;
    final joined = haystack.join(' | ');

    if (_anyMatch(joined, _formalKeywords)) return Occasion.formal;
    if (_anyMatch(joined, _workKeywords)) return Occasion.work;
    if (_anyMatch(joined, _workoutKeywords)) return Occasion.workout;
    if (_anyMatch(joined, _outdoorsKeywords)) return Occasion.outdoors;
    return null;
  }

  bool _anyMatch(String hay, List<String> needles) {
    for (final n in needles) {
      if (hay.contains(n)) return true;
    }
    return false;
  }

  static const _formalKeywords = [
    'wedding', 'gala', 'ceremony', 'black tie', 'cocktail',
    'funeral', 'graduation',
  ];
  static const _workKeywords = [
    'meeting', 'interview', 'standup', 'stand-up', 'client', 'review',
    'presentation', '1:1', '1-1', 'board', 'offsite', 'onsite', 'demo',
  ];
  static const _workoutKeywords = [
    'gym', 'workout', 'run ', 'running', 'yoga', 'pilates', 'training',
    'cycle', 'cycling', 'swim', 'crossfit', 'climb', 'hike',
  ];
  static const _outdoorsKeywords = [
    'park', 'picnic', 'beach', 'camping', 'trail', 'hiking',
  ];
}
