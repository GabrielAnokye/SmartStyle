import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single boolean: has the user seen the first-run flow for THIS account+install.
/// Reset on sign-out so a second sign-in on the same device also gets onboarded.
class OnboardingNotifier extends AsyncNotifier<bool> {
  static const _kSeen = 'onboarding.completed_v1';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeen) ?? false;
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeen, true);
    state = const AsyncData(true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSeen);
    state = const AsyncData(false);
  }
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
