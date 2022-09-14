import 'package:repo_viewer/core/infrastructure/sembast_database.dart';
import 'package:sembast/sembast.dart';

import 'github_headers.dart';

// ^ A) Creates a local storage space for Github Headers
// ^ B) Converts headers objects to and from json for storage/retrieval
// ^ C) Facilitates saving, retrieval and deletion of headers

class GithubHeadersCache {
  GithubHeadersCache(this._sembastDatabase);

  final SembastDatabase _sembastDatabase;
  // this type of store has a string index and map (json) values
  final _store = stringMapStoreFactory.store('headers');

  Future<void> saveHeaders(Uri uri, GithubHeaders headers) async {
    await _store.record(uri.toString()).put(
          _sembastDatabase.instance,
          headers.toJson(),
        );
  }

  Future<GithubHeaders?> getHeaders(Uri uri) async {
    final json = await _store.record(uri.toString()).get(
          _sembastDatabase.instance,
        );
    return json == null ? null : GithubHeaders.fromJson(json);
  }

  Future<void> deleteHeaders(Uri uri) async {
    await _store.record(uri.toString()).delete(_sembastDatabase.instance);
  }
}
