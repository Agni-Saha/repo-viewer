import 'package:dartz/dartz.dart';
import 'package:repo_viewer/core/domain/fresh.dart';
import 'package:repo_viewer/core/infrastructure/network_exceptions.dart';
import 'package:repo_viewer/github/core/domain/github_failure.dart';
import 'package:repo_viewer/github/core/domain/github_repo.dart';
import 'package:repo_viewer/github/repos/core/infrastructure/extensions.dart';
import 'package:repo_viewer/github/repos/starred_repos/infrastructure/starred_repos_local_service.dart';
import 'package:repo_viewer/github/repos/starred_repos/infrastructure/starred_repos_remote_service.dart';

/*
CORE:
A) Collects RemoteResponse from StarredReposRemoteService
B) If data is new...
      Converts from DTOs and returns Domain level entities
      Saves to local storage
C) If data is old or no connection
      returns data from storage
D) If no connectection
      marks data are out of date

LOGIC: getStarredReposPage()
It returns a RemoteResponse object, and we can map our returns based on its value.
When the RemoteResponse is either NotModified or WithNewData, we return a Fresh.yes()
object, notifying the UI that these data are fresh and there's no need to show the
flash popup.
*/

class StarredReposRepository {
  StarredReposRepository(this._remoteService, this._localService);

  final StarredReposRemoteService _remoteService;
  final StarredReposLocalService _localService;

  Future<Either<GithubFailure, Fresh<List<GithubRepo>>>> getStarredReposPage(
      int page) async {
    try {
      //making the request to API
      final remotePageItems = await _remoteService.getStarredReposPage(page);

      return right(
        await remotePageItems.when(
          noConnection: () async => Fresh.no(
            await _localService.getPage(page).then(
                  (dtos) => dtos.toDomain(),
                ),
            isNextPageAvailable: page < await _localService.getLocalPageCount(),
          ),
          notModified: (maxPage) async {
            Fresh<List<GithubRepo>> result = Fresh.yes(
              await _localService.getPage(page).then(
                    (dtos) => dtos.toDomain(),
                  ),
              isNextPageAvailable: page < maxPage,
            );
            return result;
          },
          withNewData: (data, maxPage) async {
            // Saves data to local storage
            await _localService.upsertPage(data, page);

            // Returns new data as domain entities
            return Fresh.yes(
              data.toDomain(),
              isNextPageAvailable: page < maxPage,
            );
          },
        ),
      );
    } on RestApiException catch (e) {
      return left(
        GithubFailure.api(e.errorCode),
      );
    }
  }
}
