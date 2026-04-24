import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartstyle/features/recommendations/domain/weather_snapshot.dart';

class OpenMeteoException implements Exception {
  final String message;
  OpenMeteoException(this.message);
  @override
  String toString() => 'OpenMeteoException: $message';
}

/// Thin Open-Meteo wrapper with a 15-min cache keyed by rounded coords.
/// Rounded to 2 decimals (~1.1km) to keep the cache stable for small moves.
class OpenMeteoClient {
  static const _cachePrefix = 'wx_cache_';
  static const _cacheTtl = Duration(minutes: 15);
  static const _staleAllowance = Duration(hours: 6);

  final http.Client _http;
  OpenMeteoClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  String _key(double lat, double lon) {
    final la = lat.toStringAsFixed(2);
    final lo = lon.toStringAsFixed(2);
    return '$_cachePrefix${la}_$lo';
  }

  Future<WeatherSnapshot> fetch({required double lat, required double lon}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(lat, lon);
    final cached = _readCache(prefs, key);
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
      return cached;
    }
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,apparent_temperature,precipitation_probability,wind_speed_10m'
        '&wind_speed_unit=kmh',
      );
      final resp = await _http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) {
        throw OpenMeteoException('HTTP ${resp.statusCode}');
      }
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>;
      final snap = WeatherSnapshot(
        tempC: (current['temperature_2m'] as num).toDouble(),
        feelsLikeC: (current['apparent_temperature'] as num).toDouble(),
        precipProb: ((current['precipitation_probability'] as num?) ?? 0).toDouble() / 100.0,
        windKph: (current['wind_speed_10m'] as num).toDouble(),
        fetchedAt: DateTime.now(),
      );
      await prefs.setString(key, jsonEncode(snap.toJson()));
      return snap;
    } catch (e) {
      // Fall back to stale cache if fresh enough — offline/flaky networks
      // shouldn't break the dashboard entirely.
      if (cached != null && DateTime.now().difference(cached.fetchedAt) < _staleAllowance) {
        debugPrint('OpenMeteo fetch failed, returning stale: $e');
        return cached;
      }
      rethrow;
    }
  }

  WeatherSnapshot? _readCache(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return WeatherSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

final openMeteoClientProvider = Provider<OpenMeteoClient>((_) => OpenMeteoClient());
