import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TempUnit { celsius, fahrenheit }

class AppSettings {
  final TempUnit tempUnit;
  final bool diagnosticsEnabled;

  const AppSettings({
    this.tempUnit = TempUnit.celsius,
    this.diagnosticsEnabled = true,
  });

  AppSettings copyWith({TempUnit? tempUnit, bool? diagnosticsEnabled}) {
    return AppSettings(
      tempUnit: tempUnit ?? this.tempUnit,
      diagnosticsEnabled: diagnosticsEnabled ?? this.diagnosticsEnabled,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _kUnit = 'settings.temp_unit';
  static const _kDiag = 'settings.diagnostics';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final unitStr = prefs.getString(_kUnit) ?? 'celsius';
    final diag = prefs.getBool(_kDiag) ?? true;
    return AppSettings(
      tempUnit: unitStr == 'fahrenheit' ? TempUnit.fahrenheit : TempUnit.celsius,
      diagnosticsEnabled: diag,
    );
  }

  Future<void> setUnit(TempUnit u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUnit, u.name);
    state = AsyncData((state.value ?? const AppSettings()).copyWith(tempUnit: u));
  }

  Future<void> setDiagnostics(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDiag, v);
    state = AsyncData(
      (state.value ?? const AppSettings()).copyWith(diagnosticsEnabled: v),
    );
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
