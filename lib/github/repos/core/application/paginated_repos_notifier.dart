import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/core/domain/fresh.dart';
import 'package:repo_viewer/github/core/domain/github_failure.dart';
import 'package:repo_viewer/github/core/domain/github_repo.dart';
import 'package:repo_viewer/github/core/infrastructure/pagination_config.dart';

part 'paginated_repos_notifier.freezed.dart';

/*
CORE: PaginatedReposState
There are 4 state variants that we are possible. Initial state, before even loading
or doing any stuff related to getting the pages. LoadInProgess state, that's when
we are making a request to the API and it still hasn't returned anything. LoadInSuccess
state, where we have successfully recieved all the repositories of a particular page.
LoadInFailure state, that's when we couldn't receive the repos successfully. Depending
on these states, the UI will behave accordingly.
*/

@freezed
class PaginatedReposState with _$PaginatedReposState {
  const PaginatedReposState._();

  const factory PaginatedReposState.initial(
    Fresh<List<GithubRepo>> repos,
  ) = _Initial;

  const factory PaginatedReposState.loadInProgress(
    Fresh<List<GithubRepo>> repos,
    int itemsPerPage,
  ) = _LoadInProgress;

  const factory PaginatedReposState.loadSuccess(Fresh<List<GithubRepo>> repos,
      {required bool isNextPageAvailable}) = _LoadSuccess;

  const factory PaginatedReposState.loadFailure(
    Fresh<List<GithubRepo>> repos,
    GithubFailure failure,
  ) = _LoadFailure;
}

/*
CORE: PaginatedReposNotifier
This is a stateNotifier class observing the states of PaginatedReposState.
It is in here that we call the methods of infrastructure layer and actually
make the API request.

LOGIC: _page
The number of the page of repositories is defined by _page field. Initially it
is set to 1. Only if we successfully receive the page, will we increment it.

LOGIC:
The previously loaded repositories are got from state.repos
If we get a failure, then we only show what we already have. Otherwise we append
what we already have with what we got now, and return that.
*/

class PaginatedReposNotifier extends StateNotifier<PaginatedReposState> {
  int _page = 1;

  PaginatedReposNotifier()
      : super(
          PaginatedReposState.initial(
            Fresh.yes([]),
          ),
        );

  @protected
  void resetState() {
    _page = 1;

    state = PaginatedReposState.initial(
      Fresh.yes([]),
    );
  }

  @protected
  Future<void> getNextPage(
    Future<Either<GithubFailure, Fresh<List<GithubRepo>>>> Function(int page)
        getter,
  ) async {
    // setting the initial state to loadInProgress after we have called this method
    state = PaginatedReposState.loadInProgress(
      state.repos,
      PaginationConfig.itemsPerPage,
    );

    // we make the request to get the API
    final failureOrRepos = await getter(_page);

    // depending on what we get, we update the state
    state = failureOrRepos.fold(
      (l) => PaginatedReposState.loadFailure(state.repos, l),
      (r) {
        _page++;
        return PaginatedReposState.loadSuccess(
          // Here we append the new ReposList to the existing one in the current state
          r.copyWith(
            entity: [
              ...state.repos.entity,
              ...r.entity,
            ],
          ),
          isNextPageAvailable: r.isNextPageAvailable ?? false,
        );
      },
    );
  }
}
