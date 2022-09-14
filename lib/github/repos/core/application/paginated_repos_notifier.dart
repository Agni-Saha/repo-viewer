import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/core/domain/fresh.dart';
import 'package:repo_viewer/github/core/domain/github_failure.dart';
import 'package:repo_viewer/github/core/domain/github_repo.dart';
import 'package:repo_viewer/github/core/infrastructure/pagination_config.dart';

part 'paginated_repos_notifier.freezed.dart';

// ^ ### PAGINATED_REPOS_STATE

@freezed
class PaginatedReposState with _$PaginatedReposState {
  const PaginatedReposState._();

  // ^ INITIAL
  // We'll pass an empty value but myState.repos would not be available if it was missing from one of the constructors
  const factory PaginatedReposState.initial(Fresh<List<GithubRepo>> repos) =
      _Initial;

  // ^ LOAD IN PROGRESS
  // itemsPerPage informs us how many loading indicators to render
  const factory PaginatedReposState.loadInProgress(
      Fresh<List<GithubRepo>> repos, int itemsPerPage) = _LoadInProgress;

  // ^ LOAD SUCCESS
  // The server (or local storage) will need to tell us if there is another page
  const factory PaginatedReposState.loadSuccess(Fresh<List<GithubRepo>> repos,
      {required bool isNextPageAvailable}) = _LoadSuccess;

  // ^ LOAD FAILURE
  // We still need to return the existing repos
  const factory PaginatedReposState.loadFailure(
      Fresh<List<GithubRepo>> repos, GithubFailure failure) = _LoadFailure;
}

// ^ ### PAGINATED_REPOS_NOTIFIER

typedef RepositoryGetter
    = Future<Either<GithubFailure, Fresh<List<GithubRepo>>>> Function(int page);

// ^ Facilitates calls to get more repos
// ^ Instantiates and appends to a single list of Github repos
// ^ Notifies presentation later of changes between loading, success and failure states
// ^ Provides presentation layer list of repos and GithubFailur object if failure

class PaginatedReposNotifier extends StateNotifier<PaginatedReposState> {
  // Instantiate with an empty list of repositories. Its fresh.yes because fresh.no triggers a popup
  PaginatedReposNotifier() : super(PaginatedReposState.initial(Fresh.yes([])));

  // normally you shouldnt have mutable fields in a stateNotifier but it fits our use-case in this instance
  int _page = 1;

  @protected
  void resetState() {
    _page = 1;
    state = PaginatedReposState.initial(Fresh.yes([]));
  }

  // Child classes specify as an argument what repository to get the next page from
  @protected
  Future<void> getNextPage(RepositoryGetter getter) async {
    state = PaginatedReposState.loadInProgress(
        state.repos, PaginationConfig.itemsPerPage);
    final failureOrRepos = await getter(_page);
    state = failureOrRepos.fold(
      (l) => PaginatedReposState.loadFailure(state.repos, l),
      (r) {
        _page++;
        return PaginatedReposState.loadSuccess(
            // Here we append the new ReposList to the existing one in the current state
            r.copyWith(entity: [
              ...state.repos.entity,
              ...r.entity,
            ]),
            isNextPageAvailable: r.isNextPageAvailable ?? false);
      },
    );
  }
}
