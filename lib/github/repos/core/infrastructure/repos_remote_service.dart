import 'package:dio/dio.dart';
import 'package:repo_viewer/core/infrastructure/dio_extensions.dart';
import 'package:repo_viewer/core/infrastructure/network_exceptions.dart';
import 'package:repo_viewer/core/infrastructure/remote_response.dart';
import 'package:repo_viewer/github/core/infrastructure/github_headers.dart';
import 'package:repo_viewer/github/core/infrastructure/github_headers_cache.dart';
import 'package:repo_viewer/github/core/infrastructure/github_repo_dto.dart';

/*
CORE:
This is an abstract class, providing the functionality of both starred and searched
repos feature. Its been implemented by starred_repos_remote_service.dart, that calls
the getPage method, providing it with the API url and the datastructure of conversion
Depending on the status code of the response, it returns a RemoteResponse object.
*/

abstract class ReposRemoteService {
  ReposRemoteService(
    this._dio,
    this._headersCache,
  );

  final Dio _dio;
  final GithubHeadersCache _headersCache;

  // RemoteResponse tells repository whether the data is new, unmodified or if no connection
  Future<RemoteResponse<List<GithubRepoDTO>>> getPage({
    required Uri requestUri,
    // How should we parse the json response as the structure may differ for different endpoints
    required List<dynamic> Function(dynamic json) jsonDataSelector,
  }) async {
    //getting the cached headers for etag
    final previousHeaders = await _headersCache.getHeaders(requestUri);

    //making the request with the etag.
    try {
      final response = await _dio.getUri(
        requestUri,
        options: Options(
          headers: {
            'If-None-Match': previousHeaders?.eTag ?? '',
          },
        ),
      );

      if (response.statusCode == 304) {
        return RemoteResponse.notModified(
          maxPage: previousHeaders?.link?.maxPage ?? 0,
        );
      } else if (response.statusCode == 200) {
        final headers = GithubHeaders.parse(response);
        await _headersCache.saveHeaders(requestUri, headers);

        // Converts the data from json and saves each element as a GithubRepoDTO object
        final convertedData = jsonDataSelector(response.data)
            .map(
              (e) => GithubRepoDTO.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();
        // returns the list of DTO's and maxPage
        return RemoteResponse.withNewData(
          convertedData,
          maxPage: headers.link?.maxPage ?? 1,
        );
      } else {
        throw RestApiException(response.statusCode);
      }

      // ^ NO CONNECTION
    } on DioError catch (e) {
      if (e.isNoConnectionError) {
        return const RemoteResponse.noConnection();
      } else if (e.response != null) {
        throw RestApiException(e.response?.statusCode);
      } else {
        rethrow;
      }
    }
  }
}
