import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstyle/features/intake/data/intake_queue.dart';

class IntakeQueueScreen extends ConsumerWidget {
  const IntakeQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(intakeQueueStreamProvider);
    final queue = ref.read(intakeQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload queue'),
        actions: [
          IconButton(
            tooltip: 'Retry all',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await queue.retryAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Retrying queued uploads…')),
                );
              }
            },
          ),
        ],
      ),
      body: queueAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Queue is empty.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final q = items[i];
              return _QueueTile(
                item: q,
                thumbFuture: queue.resolveFile(q),
                onRemove: () => queue.remove(q.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final QueuedItem item;
  final Future<File> thumbFuture;
  final VoidCallback onRemove;
  const _QueueTile({
    required this.item,
    required this.thumbFuture,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: FutureBuilder<File>(
            future: thumbFuture,
            builder: (context, snap) {
              final file = snap.data;
              if (file == null || !file.existsSync()) {
                return Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                );
              }
              return Image.file(file, width: 56, height: 56, fit: BoxFit.cover);
            },
          ),
        ),
        title: Text(item.category),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusChip(status: item.status),
            if (item.lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                item.lastError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final QueuedStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      QueuedStatus.pending => ('Pending', Colors.blueGrey),
      QueuedStatus.uploading => ('Uploading', Colors.blue),
      QueuedStatus.done => ('Done', Colors.green),
      QueuedStatus.failed => ('Failed', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
