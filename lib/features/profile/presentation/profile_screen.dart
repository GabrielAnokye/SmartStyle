import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstyle/core/services/supabase_service.dart';
import 'package:smartstyle/features/onboarding/data/onboarding_repository.dart';
import 'package:smartstyle/features/profile/data/settings_repository.dart';

const String kAppVersion = '1.0.0';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: settingsAsync.when(
        data: (s) => ListView(
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Signed in as'),
              subtitle: Text(user?.email ?? '—'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.thermostat),
              title: const Text('Temperature units'),
              trailing: SegmentedButton<TempUnit>(
                segments: const [
                  ButtonSegment(value: TempUnit.celsius, label: Text('°C')),
                  ButtonSegment(value: TempUnit.fahrenheit, label: Text('°F')),
                ],
                selected: {s.tempUnit},
                onSelectionChanged: (sel) =>
                    ref.read(settingsProvider.notifier).setUnit(sel.first),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bug_report_outlined),
              title: const Text('Send diagnostics'),
              subtitle: const Text('Anonymous crash and performance reports'),
              value: s.diagnosticsEnabled,
              onChanged: (v) => ref.read(settingsProvider.notifier).setDiagnostics(v),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () => _confirmSignOut(context, ref),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version'),
              subtitle: const Text('SmartStyle $kAppVersion'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign back in to access your closet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      // Reset onboarding BEFORE sign-out so the next account starts fresh and
      // a brief flash of the dashboard isn't seen between states.
      await ref.read(onboardingProvider.notifier).reset();
      await ref.read(supabaseClientProvider).auth.signOut();
      // authStateProvider change triggers the router redirect to /login.
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }
}
