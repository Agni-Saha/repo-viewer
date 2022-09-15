import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:repo_viewer/github/core/domain/user.dart';

part 'github_repo.freezed.dart';

/*
CORE:
This is the placeholder class for the github repositories that the server provides.
We are only interested with these fields only, for this feature. Since there are more
than 1 fields of the owner required, so we create another class for it.
*/

@freezed
class GithubRepo with _$GithubRepo {
  const GithubRepo._();
  const factory GithubRepo({
    required User owner,
    required String name,
    required String description,
    required int stargazersCount,
  }) = _GithubRepo;

// This returns a given repository path - Always provide getters for entities to hide the structure from
// other parts of the app
  String get fullName => '${owner.name}/$name';
}
