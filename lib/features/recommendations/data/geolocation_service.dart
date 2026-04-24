import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationFix {
  final double lat;
  final double lon;
  final String? label; // e.g. "London, GB"
  const LocationFix({required this.lat, required this.lon, this.label});

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon, 'label': label};
  factory LocationFix.fromJson(Map<String, dynamic> j) => LocationFix(
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        label: j['label'] as String?,
      );
}

class GeolocationException implements Exception {
  final String message;
  GeolocationException(this.message);
  @override
  String toString() => 'GeolocationException: $message';
}

class GeolocationService {
  static const _manualKey = 'manual_city_fix';
  final http.Client _http;
  GeolocationService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  /// Preference order: manual city (if set) → GPS → throw. Manual wins so a
  /// user who set "home base = Accra" isn't overridden on a trip unless they
  /// clear it.
  Future<LocationFix> currentFix() async {
    final manual = await loadManual();
    if (manual != null) return manual;
    return _gpsFix();
  }

  Future<LocationFix> _gpsFix() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw GeolocationException('Location services disabled.');
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw GeolocationException('Location permission denied.');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return LocationFix(lat: pos.latitude, lon: pos.longitude);
  }

  /// Uses Open-Meteo's free geocoding API — no key required.
  Future<List<LocationFix>> searchCity(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeQueryComponent(query)}&count=5&language=en&format=json',
    );
    final resp = await _http.get(uri).timeout(const Duration(seconds: 6));
    if (resp.statusCode != 200) {
      throw GeolocationException('Geocoding failed: HTTP ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>?) ?? const [];
    return results.map((r) {
      final m = r as Map<String, dynamic>;
      final name = m['name'] as String?;
      final country = m['country_code'] as String?;
      return LocationFix(
        lat: (m['latitude'] as num).toDouble(),
        lon: (m['longitude'] as num).toDouble(),
        label: [name, country].where((e) => e != null && e.isNotEmpty).join(', '),
      );
    }).toList();
  }

  Future<void> saveManual(LocationFix fix) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_manualKey, jsonEncode(fix.toJson()));
  }

  Future<LocationFix?> loadManual() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_manualKey);
    if (raw == null) return null;
    try {
      return LocationFix.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearManual() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_manualKey);
  }
}

final geolocationServiceProvider = Provider<GeolocationService>((_) => GeolocationService());
