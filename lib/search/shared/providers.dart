import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/core/shared/providers.dart';

import '../application/search_history_notifier.dart';
import '../infrastructure/search_history_repository.dart';

final searchHistoryNotifierProvider =
    StateNotifierProvider<SearchHistoryNotifier, AsyncValue<List<String>>>(
        (ref) => SearchHistoryNotifier(
              ref.watch(searchHistoryRepositoryProvider),
            ));

final searchHistoryRepositoryProvider =
    Provider((ref) => SearchHistoryRepository(ref.watch(sembastProvider)));
