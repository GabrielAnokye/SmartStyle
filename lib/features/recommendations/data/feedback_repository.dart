import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartstyle/core/services/supabase_service.dart';

class FeedbackRecord {
  final Set<String> itemIds;
  final DateTime createdAt;
  final String? reason;

  const FeedbackRecord({
    required this.itemIds,
    required this.createdAt,
    this.reason,
  });
}

class FeedbackRepository {
  final SupabaseClient _supabase;
  FeedbackRepository(this._supabase);

  Future<void> logNegative({
    required List<String> itemIds,
    String? reason,
    String? contextHash,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('Not signed in.');
    await _supabase.from('outfit_feedback').insert({
      'user_id': user.id,
      'item_ids': itemIds,
      'reason': ?reason,
      'context_hash': ?contextHash,
    });
  }

  /// Rows from the last [since], newest first. The engine reads these to
  /// apply a decaying penalty to outfits that share items with recent rejects.
  Future<List<FeedbackRecord>> recentNegative({
    Duration since = const Duration(days: 14),
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const [];
    final cutoff = DateTime.now().toUtc().subtract(since).toIso8601String();
    final rows = await _supabase
        .from('outfit_feedback')
        .select('item_ids, created_at, reason')
        .eq('user_id', user.id)
        .gte('created_at', cutoff)
        .order('created_at', ascending: false);
    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      return FeedbackRecord(
        itemIds: (m['item_ids'] as List).cast<String>().toSet(),
        createdAt: DateTime.parse(m['created_at'] as String),
        reason: m['reason'] as String?,
      );
    }).toList();
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.watch(supabaseClientProvider));
});
