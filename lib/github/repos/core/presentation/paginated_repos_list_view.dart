import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:repo_viewer/core/presentation/toasts.dart';
import 'package:repo_viewer/github/core/presentation/no_results_display.dart';
import 'package:repo_viewer/github/repos/core/application/paginated_repos_notifier.dart';
import 'package:repo_viewer/github/repos/core/presentation/failure_repo_tile.dart';
import 'package:repo_viewer/github/repos/core/presentation/loading_repo_tile.dart';
import 'package:repo_viewer/github/repos/core/presentation/repo_tile.dart';

/*
CORE:
The respective notifier provider of layers are read and passed into this common class.
This class gets the value of the data from it's super class (either the Starred Repos
or the Searched Repos Presentation Layer).
The data that it receives is a variant of PaginatedReposState and using that, we display
the UI accordingly.
*/

class PaginatedReposListView extends StatefulWidget {
  // We can import either the starred repos notifier or the search notifier
  // on the fly (i.e., during runtime)
  final AutoDisposeStateNotifierProvider<PaginatedReposNotifier,
      PaginatedReposState> paginatedReposNotifierProvider;
  final void Function(WidgetRef ref) getNextPage;
  final String noResultsMessage;

  const PaginatedReposListView({
    Key? key,
    required this.paginatedReposNotifierProvider,
    required this.getNextPage,
    required this.noResultsMessage,
  }) : super(key: key);

  @override
  State<PaginatedReposListView> createState() => _PaginatedReposListViewState();
}

class _PaginatedReposListViewState extends State<PaginatedReposListView> {
  bool canLoadNextPage = false;
  bool hasAlreadyShownNoConnectionToast = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(widget.paginatedReposNotifierProvider);

        // ^ This is all just a function that manages whether new data can be
        // scrolled and whether a no connect toast needs to be displayed
        ref.listen<PaginatedReposState>(
          widget.paginatedReposNotifierProvider,
          (previous, next) {
            next.map(
              initial: (_) => canLoadNextPage = true,
              loadInProgress: (_) => canLoadNextPage = false,
              loadSuccess: (_) {
                if (!_.repos.isFresh && !hasAlreadyShownNoConnectionToast) {
                  hasAlreadyShownNoConnectionToast = true;
                  showNoConnectionToast(
                    "You're not online, some information may be outdated.",
                    context,
                  );
                }
                // answer derived from repository
                canLoadNextPage = _.isNextPageAvailable;
              },
              // False because we instead trigger the reload with the button
              // on the failure list tile
              loadFailure: (_) => canLoadNextPage = false,
            );
          },
        );

        // ^ This is actually what our builder returns
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            // limit is defined as 1/3rd of the way from the bottom of the screen
            // when at end of current list
            final limit =
                metrics.maxScrollExtent - (metrics.viewportDimension / 3);
            // getNextPage is beyond limit
            if (canLoadNextPage && metrics.pixels >= limit) {
              canLoadNextPage = false;
              widget.getNextPage(ref);
            }
            // read onNotification info to understand why we set false
            return false;
          },
          child: state.maybeWhen(
            loadSuccess: (repos, _) => repos.entity.isEmpty,
            orElse: () => false,
          )
              ? NoResultsDisplay(
                  message: widget.noResultsMessage,
                )
              : _PaginatedListView(
                  state: state,
                ),
        );
      },
    );
  }
}

// ^ ####
class _PaginatedListView extends StatelessWidget {
  const _PaginatedListView({
    Key? key,
    required this.state,
  }) : super(key: key);

  final PaginatedReposState state;

  @override
  Widget build(BuildContext context) {
    // Getting the height of the floating search bar to use in our padding
    final fsbHeight =
        context.findAncestorWidgetOfExactType<FloatingSearchBar>()?.height;
    return ListView.builder(
      padding: fsbHeight == null
          ? EdgeInsets.zero
          : EdgeInsets.only(
              top: fsbHeight + 8 + MediaQuery.of(context).padding.top,
            ),
      itemCount: state.map(
        initial: (_) => 0,
        loadInProgress: (_) => _.repos.entity.length + _.itemsPerPage,
        loadSuccess: (_) => _.repos.entity.length,
        loadFailure: (_) => _.repos.entity.length + 1,
      ),
      itemBuilder: (context, index) {
        return state.map(
          initial: (_) => Container(),
          loadInProgress: (_) {
            if (index < _.repos.entity.length) {
              return RepoTile(
                repo: _.repos.entity[index],
              );
            } else {
              return const LoadingRepoTile();
            }
          },
          loadSuccess: (_) => RepoTile(
            repo: _.repos.entity[index],
          ),
          loadFailure: (_) {
            if (index < _.repos.entity.length) {
              return RepoTile(
                repo: _.repos.entity[index],
              );
            } else {
              return FailureRepoTile(
                failure: _.failure,
              );
            }
          },
        );
      },
    );
  }
}
