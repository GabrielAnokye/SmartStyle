import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartstyle/features/intake/data/intake_queue.dart';

class IntakeHubScreen extends ConsumerWidget {
  const IntakeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(intakeQueueStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Items')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionCard(
              icon: Icons.burst_mode,
              title: 'Batch camera',
              subtitle: 'Shoot several items, review them together.',
              onTap: () => context.push('/add/batch'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.photo_library,
              title: 'Manual add',
              subtitle: 'Pick a single photo and fill out details.',
              onTap: () => context.push('/add/manual'),
            ),
            const SizedBox(height: 24),
            queueAsync.when(
              data: (q) => q.isEmpty
                  ? const SizedBox.shrink()
                  : Card(
                      color: Colors.amber.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.cloud_queue),
                        title: Text('${q.length} item(s) queued for upload'),
                        subtitle: Text(q.any((e) => e.status == QueuedStatus.failed)
                            ? 'One or more uploads failed. Tap to review.'
                            : 'Syncing in the background. Tap to view.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/add/queue'),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
