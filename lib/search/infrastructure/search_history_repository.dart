import 'package:repo_viewer/core/infrastructure/sembast_database.dart';
import 'package:sembast/sembast.dart';

class SearchHistoryRepository {
  SearchHistoryRepository(this._sembastDatabase);

  final SembastDatabase _sembastDatabase;
  // We do not need anything as complex as a map for this store, it's strings only
  final _store = StoreRef<int, String>('searchHistory');

  static const historyLength = 10;

  // Stream is best because we want the list to updated immediately when we delete items, and filter immediately when
  // we enter substrings without having to call a seperate get method
  Stream<List<String>> watchSearchTerms({String? filter}) {
    return _store
        .query(
          finder: filter != null && filter.isNotEmpty
              ? Finder(
                  filter: Filter.custom(
                    // results will dynamically filter to match whats typed in the search bar
                    (record) => (record.value as String).startsWith(filter),
                  ),
                )
              // results will not filter at all if nothing is typed in
              : null,
        )
        // need to convert the snapshot to a list
        .onSnapshots(_sembastDatabase.instance)
        // reversed because we want latest search terms to be at top of list, not the end
        .map(
          (records) => records.reversed.map((e) => e.value).toList(),
        );
  }

  // ^ ### Public methods
  // ^ these can be called by the transaction layer, we pass in the _sembastDatabase.instance as the DatabaseClient

  Future<void> addSearchTerm(String term) =>
      _addSearchTerm(term, _sembastDatabase.instance);

  Future<void> deleteSearchTerm(String term) =>
      _deleteSearchTerm(term, _sembastDatabase.instance);

  // When we click a search term from history we want to add it to top of the list
  Future<void> putSearchTermFirst(String term) async {
    // Running consecutive write operations on a db can cause deadline. We use a 'transaction' as per sembast docs
    await _sembastDatabase.instance.transaction((transaction) async {
      await _deleteSearchTerm(term, transaction);
      await _addSearchTerm(term, transaction);
    });
  }

  // ^ ### Private methods
  // ^ these require a DatabaseClient to be specified because they may be called in the context of a transaction

  Future<void> _addSearchTerm(String term, DatabaseClient dbClient) async {
    // First we check if the term already exists in the database
    final existingKey = await _store.findKey(
      dbClient,
      finder: Finder(
        filter: Filter.custom(
          (record) => record.value == term,
        ),
      ),
    );

    // If it does we simply put the search term first
    if (existingKey != null) {
      putSearchTermFirst(term);
      return;
    }

    // if it doesn't we add it to the database, deleting anything over 10 entries from oldest first
    await _store.add(dbClient, term);
    final count = await _store.count(dbClient);
    if (count > historyLength) {
      await _store.delete(
        dbClient,
        finder: Finder(
          limit: count - historyLength,
        ),
      );
    }
  }

  Future<void> _deleteSearchTerm(String term, DatabaseClient dbClient) async {
    await _store.delete(
      dbClient,
      finder: Finder(
        filter: Filter.custom(
          (record) => record.value == term,
        ),
      ),
    );
  }
}
