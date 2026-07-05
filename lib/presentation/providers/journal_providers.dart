import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/journal_entry.dart';
import 'repository_providers.dart';

class JournalNotifier extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  final Ref ref;
  JournalNotifier(this.ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await ref.read(journalRepositoryProvider).getAll());
  }

  Future<void> add(JournalEntry entry) async {
    await ref.read(journalRepositoryProvider).add(entry);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(journalRepositoryProvider).delete(id);
    await refresh();
  }
}

final journalProvider = StateNotifierProvider<JournalNotifier, AsyncValue<List<JournalEntry>>>(
  (ref) => JournalNotifier(ref),
);
