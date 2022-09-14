// Though we do cache the starred status, we ALWAYS assume it is not up to date and read it from the API if possible.
// There is no eTag for starred status so we have to assume the user may have starred something outside of the app

// ^ Manages storage and retrieval of the 50 most recently accessed detail pages

import 'package:repo_viewer/core/infrastructure/sembast_database.dart';
import 'package:repo_viewer/github/core/infrastructure/github_headers_cache.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/timestamp.dart';

import 'github_repo_detail_dto.dart';

class RepoDetailLocalService {
  RepoDetailLocalService(this._sembastDatabase, this._headersCache);

  final SembastDatabase _sembastDatabase;
  final _store = stringMapStoreFactory.store('repoDetails');
  final GithubHeadersCache _headersCache;
  static const cacheSize = 50;

  Future<void> upsertRepoDetails(
      GithubRepoDetailDTO githubRepoDetailDTO) async {
    // ADD RECORD TO STORAGE
    await _store.record(githubRepoDetailDTO.fullName).put(
          _sembastDatabase.instance,
          githubRepoDetailDTO.toSembast(),
        );

    // RETURN LIST OF KEYS
    final keys = await _store.findKeys(_sembastDatabase.instance,
        finder: Finder(sortOrders: [
          SortOrder(GithubRepoDetailDTO.lastUsedFieldName, false)
        ]));

    // DELETE OLDEST KEY RECORDS IF EXCEEDING CACHE LIMIT ALONG WITH ENTRY FROM HEADERS CACHE
    if (keys.length > cacheSize) {
      final keysToRemove = keys.sublist(cacheSize);
      for (final key in keysToRemove) {
        await _store.record(key).delete(_sembastDatabase.instance);
        await _headersCache
            .deleteHeaders(Uri.https('api.github.com', '/repos/$key/readme'));
      }
    }
  }

  // nullable because there might not be a record in storage
  Future<GithubRepoDetailDTO?> getRepoDetails(String fullRepoName) async {
    final record = _store.record(fullRepoName);
    // We update the lastUsed value which only exists in storage so the record isnt deleted for being old
    await record.update(_sembastDatabase.instance,
        {GithubRepoDetailDTO.lastUsedFieldName: Timestamp.now()});
    final recordSnapshot = await record.getSnapshot(_sembastDatabase.instance);

    if (recordSnapshot == null) {
      return null;
    }
    return GithubRepoDetailDTO.fromSembast(recordSnapshot);
  }
}
