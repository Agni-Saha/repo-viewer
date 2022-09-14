import 'package:dio/dio.dart';
import 'package:repo_viewer/core/infrastructure/remote_response.dart';
import 'package:repo_viewer/github/core/infrastructure/github_headers_cache.dart';
import 'package:repo_viewer/github/core/infrastructure/github_repo_dto.dart';
import 'package:repo_viewer/github/core/infrastructure/pagination_config.dart';
import 'package:repo_viewer/github/repos/core/infrastructure/repos_remote_service.dart';

// ^ A) Extends all the functionality of ReposRemoteService (which is shared with our starred repos feature)
// ^ B) Specifies the following which differs from the starred repos feature
// ^    - The endpoint URI to which we request the data
// ^    - The part of json the which we convert

class SearchedReposRemoteService extends ReposRemoteService {
  SearchedReposRemoteService(
    Dio dio,
    GithubHeadersCache headersCache,
  ) : super(dio, headersCache);

  Future<RemoteResponse<List<GithubRepoDTO>>> getSearchedReposPage(
    String query,
    int page,
  ) async {
    return super.getPage(
      requestUri: Uri.https(
        'api.github.com',
        '/search/repositories',
        {
          'q': query,
          'page': '$page',
          'per_page': PaginationConfig.itemsPerPage.toString(),
        },
      ),
      jsonDataSelector: (json) => json['items'] as List<dynamic>,
    );
  }
}
