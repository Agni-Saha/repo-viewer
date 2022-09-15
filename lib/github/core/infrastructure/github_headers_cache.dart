import 'package:repo_viewer/core/infrastructure/sembast_database.dart';
import 'package:sembast/sembast.dart';

import 'github_headers.dart';

/*
CORE:
This is the class that we use to store the etag and page value of the server
data into our sembast database in a store "header". It's a simple class where
we have implemented three classes to save, get and delete the headers data.
All these methods receive a URL and a header and we store them as key and value
respectively in the database.
*/

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
