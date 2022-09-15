import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/core/domain/fresh.dart';
import 'package:repo_viewer/github/core/domain/github_failure.dart';
import 'package:repo_viewer/github/detail/domain/github_repo_detail.dart';
import 'package:repo_viewer/github/detail/infrastructure/repo_detail_repository.dart';

part 'repo_detail_notifier.freezed.dart';

@freezed
class RepoDetailState with _$RepoDetailState {
  const RepoDetailState._();
  const factory RepoDetailState.initial({
    @Default(false) bool hasStarredStatusChanged,
  }) = _Initial;
  const factory RepoDetailState.loadInProgress({
    @Default(false) bool hasStarredStatusChanged,
  }) = _LoadInProgress;
  const factory RepoDetailState.loadSuccess(
    Fresh<GithubRepoDetail?> repoDetail, {
    @Default(false) bool hasStarredStatusChanged,
  }) = _LoadSuccess;
  const factory RepoDetailState.loadFailure(
    GithubFailure failure, {
    @Default(false) bool hasStarredStatusChanged,
  }) = _LoadFailure;
}

class RepoDetailNotifier extends StateNotifier<RepoDetailState> {
  RepoDetailNotifier(this._repository)
      : super(
          const RepoDetailState.initial(),
        );

  final RepoDetailRepository _repository;

  Future<void> getRepoDetail(String fullRepoName) async {
    state = const RepoDetailState.loadInProgress();
    final failureOrRepoDetail = await _repository.getRepoDetail(fullRepoName);
    state = failureOrRepoDetail.fold(
      (l) => RepoDetailState.loadFailure(l),
      (r) => RepoDetailState.loadSuccess(r),
    );
  }

  // This method implements 'Optimisic Update' - It will call the success animation before the actual server call
  // is made, and revert to the previous state if the call is unsuccessful
  Future<void> switchStarredStatus(GithubRepoDetail repoDetail) async {
    state.maybeMap(
      // if the state is anything other than loadSuccess we will do nothing
      orElse: () {},
      loadSuccess: (successState) async {
        final stateCopy = successState.copyWith();
        final repoDetail = successState.repoDetail.entity;
        if (repoDetail != null) {
          // Changing the state optimistically, just changing the starred details for now to trigger the animation
          state = successState.copyWith.repoDetail(
            entity: repoDetail.copyWith(starred: !repoDetail.starred),
          );
          final failureOrSuccess =
              await _repository.switchStarredStatus(repoDetail);
          failureOrSuccess.fold(
            // If the uodate failed, revert to the previous state
            (l) => state == stateCopy,
            // if the update returned null, revert to the previous state
            (r) => r == null
                ? state == stateCopy
                // otherwise lets go with the optimistically set state but update this value
                : state = state.copyWith(
                    hasStarredStatusChanged: true,
                  ),
          );
        }
      },
    );
  }
}
