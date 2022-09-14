import 'package:repo_viewer/github/repos/core/application/paginated_repos_notifier.dart';
import 'package:repo_viewer/github/repos/starred_repos/infrastructure/starred_repos_repository.dart';

// ^ A) Extends all the functionality of the PaginatedReposNotifier (which is shared with our searched repos feature)
// ^ B) Returns value of getNextPage from the StarredReposRepository

class StarredReposNotifier extends PaginatedReposNotifier {
  StarredReposNotifier(this._repository);

  final StarredReposRepository _repository;

  Future<void> getFirstStarredReposPage() async {
    super.resetState();
    await getNextStarredReposPage();
  }

  Future<void> getNextStarredReposPage() async {
    super.getNextPage((page) => _repository.getStarredReposPage(page));
  }
}
