// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:repo_viewer/search/shared/providers.dart';

// ^ Generic search bar that can be used by multiple search pages
// ^ A) Provides the search bar and search history UI
// ^ B) Provides widgets/buttons from which the Search Notifier methods can be called
// ^ C) Provides different UI adapting to the Notifier state (data, isLoading, error)

class SearchBar extends ConsumerStatefulWidget {
  const SearchBar({
    Key? key,
    required this.title,
    required this.hint,
    required this.body,
    required this.onShouldNavigateToResultPage,
    required this.onSignoutButtonPressed,
  }) : super(key: key);

  final String title;
  final String hint;
  final Widget body;
  final void Function(String searchTerm) onShouldNavigateToResultPage;
  final void Function() onSignoutButtonPressed;

  @override
  ConsumerState<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<SearchBar> {
  // We need a controller to perform actions such as clear
  late FloatingSearchBarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FloatingSearchBarController();
    ref.read(searchHistoryNotifierProvider.notifier).watchSearchTerms();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // nested functions
    void pushPageAndPutFirstInHistory(String searchTerm) {
      widget.onShouldNavigateToResultPage(searchTerm);
      ref
          .read(searchHistoryNotifierProvider.notifier)
          .putSearchTermFirst(searchTerm);
      _controller.close();
    }

    void pushPageAndAddToHistory(String searchTerm) {
      widget.onShouldNavigateToResultPage(_controller.query);
      ref
          .read(searchHistoryNotifierProvider.notifier)
          .addSearchTerm(_controller.query);
      _controller.close();
    }

    // ^ SEARCH BAR WIDGET
    return FloatingSearchBar(
      controller: _controller,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headline6,
          ),
          Text(
            'Tap to search',
            style: Theme.of(context).textTheme.caption,
          ),
        ],
      ),
      hint: widget.hint,
      automaticallyImplyBackButton: false,
      // Returns a different back arrow depending on whether platform is IOS or Android
      leadingActions: [
        if (AutoRouter.of(context).canPopSelfOrChildren &&
            (Platform.isIOS || Platform.isMacOS))
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            splashRadius: 18,
            onPressed: () {
              AutoRouter.of(context).pop();
            },
          )
        else if (AutoRouter.of(context).canPopSelfOrChildren)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            splashRadius: 18,
            onPressed: () {
              AutoRouter.of(context).pop();
            },
          )
      ],
      actions: [
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
        FloatingSearchBarAction(
          child: IconButton(
            splashRadius: 18,
            onPressed: () {
              widget.onSignoutButtonPressed();
            },
            icon: const Icon(
              MdiIcons.logoutVariant,
            ),
          ),
        )
      ],
      onQueryChanged: (query) {
        ref
            .read(searchHistoryNotifierProvider.notifier)
            .watchSearchTerms(filter: query);
      },
      onSubmitted: (query) => pushPageAndAddToHistory(query),

      // ^ DROPDOWN HISTORY WIDGET WITH DATA, LOADING & ERROR STATES
      builder: (context, transition) {
        return Material(
          color: Theme.of(context).cardColor,
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          // This means the children will respect the circular border radius (with splash animation for example)
          clipBehavior: Clip.hardEdge,
          child: Consumer(
            builder: (context, ref, child) {
              final searchHistoryState = ref.watch(
                searchHistoryNotifierProvider,
              );
              return searchHistoryState.map(
                // ^ Data case
                data: (history) {
                  if (_controller.query.isEmpty && history.value.isEmpty) {
                    return Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: Text(
                        'Start searching',
                        style: Theme.of(context).textTheme.caption,
                      ),
                    );
                  } else if (history.value.isEmpty) {
                    return ListTile(
                      title: Text(_controller.query),
                      leading: const Icon(Icons.search),
                      onTap: () => pushPageAndAddToHistory(_controller.query),
                    );
                  }
                  return Column(
                    children: history.value
                        .map(
                          (term) => ListTile(
                            title: Text(
                              term,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: const Icon(Icons.history),
                            trailing: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                ref
                                    .read(
                                      searchHistoryNotifierProvider.notifier,
                                    )
                                    .deleteSearchTerm(term);
                              },
                            ),
                            // ^ When we tap a term we want to search it and promote it to most recent in our history
                            onTap: () => pushPageAndPutFirstInHistory(term),
                          ),
                        )
                        .toList(),
                  );
                },
                // ^ Error case
                error: (_) => ListTile(
                  title: Text(
                    'Very unexpected error ${_.error}',
                  ),
                ),
                // ^ Loading
                loading: (_) => const ListTile(
                  title: LinearProgressIndicator(),
                ),
              );
            },
          ),
        );
      },
      // ^ BODY WIDGET (The list)
      // This causes the FSB to hide when the user scrolls down
      body: Container(
        margin: const EdgeInsets.only(
          top: 16,
        ),
        child: FloatingSearchBarScrollNotifier(
          child: widget.body,
        ),
      ),
    );
  }
}
