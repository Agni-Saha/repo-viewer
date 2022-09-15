// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:repo_viewer/core/domain/fresh.dart';
import 'package:repo_viewer/core/infrastructure/network_exceptions.dart';
import 'package:repo_viewer/github/core/domain/github_failure.dart';
import 'package:repo_viewer/github/detail/domain/github_repo_detail.dart';
import 'package:repo_viewer/github/detail/infrastructure/github_repo_detail_dto.dart';

import 'repo_detail_local_service.dart';
import 'repo_detail_remote_service.dart';

// ^ A) Facilitates collection of RemoteResponse from RepoDetailRemoteService
// ^ B) If data is new...
// ^       Consolidates the different data points within our DTO entity
// ^       Saves to local storage
// ^       Converts and returns DTO as domain entity marking it as FRESH
// ^ C) If data is old
// ^       Collects DTO from local storage
// ^       Quaries starred status and updated DTO with result
// ^       Converts and returns DTO as domain entity marking it as FRESH
// ^ D) If no connection
// ^       Collects DTO from local storage
// ^       Converts and returns DTO as domain entity marking it as NOT FRESH

class RepoDetailRepository {
  RepoDetailRepository(this._localService, this._remoteService);

  final RepoDetailLocalService _localService;
  final RepoDetailRemoteService _remoteService;

  Future<Either<GithubFailure, Fresh<GithubRepoDetail?>>> getRepoDetail(
    String fullRepoName,
  ) async {
    try {
      final htmlRemoteResponse =
          await _remoteService.getReadmeHtml(fullRepoName);
      return right(
        await htmlRemoteResponse.when(
          // ^ NO CONNECTION
          noConnection: () async => Fresh.no(
            await _localService.getRepoDetails(fullRepoName).then(
                  (dto) => dto?.toDomain(),
                ),
          ),
          // ^ NOT MODIFIED
          notModified: (_) async {
            final cached = await _localService.getRepoDetails(fullRepoName);
            // We can only determine that the html content is not modified so we still query the
            // remote service for the starred status
            final starred = await _remoteService.getStarredStatus(fullRepoName);
            final withUpdatedStarredField = cached?.copyWith(
              starred: starred ?? false,
            );
            return Fresh.yes(
              withUpdatedStarredField?.toDomain(),
            );
          },
          // ^ NEW DATA
          withNewData: (html, _) async {
            final starred = await _remoteService.getStarredStatus(fullRepoName);
            final dto = GithubRepoDetailDTO(
              fullName: fullRepoName,
              html: html,
              starred: starred ?? false,
            );
            await _localService.upsertRepoDetails(dto);
            return Fresh.yes(
              dto.toDomain(),
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

  /// returns right(null) if there is no internet connection
  Future<Either<GithubFailure, Unit?>> switchStarredStatus(
      GithubRepoDetail repoDetail) async {
    try {
      final actionCompleted = await _remoteService.switchStarredStatus(
        repoDetail.fullName,
        isCurrentlyStarred: repoDetail.starred,
      );
      return right(actionCompleted);
    } on RestApiException catch (e) {
      return left(
        GithubFailure.api(e.errorCode),
      );
    }
  }
}
