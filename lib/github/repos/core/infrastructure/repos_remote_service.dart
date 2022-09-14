import 'package:dio/dio.dart';
import 'package:repo_viewer/core/infrastructure/dio_extensions.dart';
import 'package:repo_viewer/core/infrastructure/network_exceptions.dart';
import 'package:repo_viewer/core/infrastructure/remote_response.dart';
import 'package:repo_viewer/github/core/infrastructure/github_headers.dart';
import 'package:repo_viewer/github/core/infrastructure/github_headers_cache.dart';
import 'package:repo_viewer/github/core/infrastructure/github_repo_dto.dart';

// ^ Abstract class providing common functionality which is shared between starredRepos and searchRepos remote services

// ^ A) Handles requests to the API for repoPages,
// ^ B) it maintains a cache of previousHeader with which we add to our requests to check if a repoPage has been updated or not.
// ^ C) it returns a 'RemoteResponse' which specifies whether query data is new, notUpdated or if there is no internet
// ^ D) if data is new, it returns it as a list of DTO's
// ^ E) it prevents searching beyond max available pages

abstract class ReposRemoteService {
  ReposRemoteService(
    this._dio,
    this._headersCache,
  );

  final Dio _dio; // facilitates HTTP requests
  final GithubHeadersCache
      _headersCache; // enables us to check if repo has been updated via eTag records, starred repos only

  // RemoteResponse tells repository whether the data is new, unmodified or if no connection
  Future<RemoteResponse<List<GithubRepoDTO>>> getPage({
    // Which endpoint should we query?
    required Uri requestUri,
    // How should we parse the json response as the structure may differ for different endpoints
    required List<dynamic> Function(dynamic json) jsonDataSelector,
  }) async {
    // What eTags have we already received from the API?
    final previousHeaders = await _headersCache.getHeaders(requestUri);
    try {
      final response = await _dio.getUri(
        requestUri,
        options: Options(
          headers: {
            //  Here we're providing the server our previousHeaders eTag, if it matches we receive a 304
            'If-None-Match': previousHeaders?.eTag ?? '',
          },
        ),
      );

      // ^ 304 RECEIVED (NOT MODIFIED)
      if (response.statusCode == 304) {
        return RemoteResponse.notModified(
            maxPage: previousHeaders?.link?.maxPage ?? 0);

        // ^ 200 RECEIVED (NEW DATA)
      } else if (response.statusCode == 200) {
        //  saving headers ready for next time
        final headers = GithubHeaders.parse(response);
        await _headersCache.saveHeaders(requestUri, headers);
        // Converts the data from json and saves each element as a GithubRepoDTO object
        final convertedData = jsonDataSelector(response.data)
            .map((e) => GithubRepoDTO.fromJson(e as Map<String, dynamic>))
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
