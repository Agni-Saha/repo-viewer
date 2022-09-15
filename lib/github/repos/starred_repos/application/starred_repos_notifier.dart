import 'package:repo_viewer/github/repos/core/application/paginated_repos_notifier.dart';
import 'package:repo_viewer/github/repos/starred_repos/infrastructure/starred_repos_repository.dart';

/*
It extends the functionality of PaginatedReposNotifier abstract class and
implements it for starred repos feature.
*/

class StarredReposNotifier extends PaginatedReposNotifier {
  final StarredReposRepository _repository;

  StarredReposNotifier(this._repository);

  Future<void> getFirstStarredReposPage() async {
    super.resetState();
    await getNextStarredReposPage();
  }

  Future<void> getNextStarredReposPage() async {
    super.getNextPage(
      (page) => _repository.getStarredReposPage(page),
    );
  }
}
