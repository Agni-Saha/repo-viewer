import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:repo_viewer/github/core/domain/github_repo.dart';
import 'package:repo_viewer/github/core/infrastructure/user_dto.dart';

part 'github_repo_dto.freezed.dart';
part 'github_repo_dto.g.dart';

/*
CORE:
This class is used to convert the server data into valid dart object that can be
used successfully by UI and other layers. We are using freezed to create the data
class and jsonSerializable to add functionality of converting data to and from json.

LOGIC:
If we write fromJson only, toJson will be automatically created. We don't need to
add much logic in here. Just need to specify which field will hold what and what
will be the name of json key from which the data will be extracted.
*/


String _descriptionFromJson(Object? json) {
  return (json as String?) ?? '';
}

@freezed
class GithubRepoDTO with _$GithubRepoDTO {
  const GithubRepoDTO._();
  const factory GithubRepoDTO({
    required UserDTO owner,
    required String name,
    // Ensuring we never receive null
    @JsonKey(fromJson: _descriptionFromJson) required String description,
    
    // This is the only field with a different json key or type to our field name or type
    @JsonKey(name: 'stargazers_count') required int stargazersCount,
  }) = _GithubRepoDTO;

  factory GithubRepoDTO.fromJson(Map<String, dynamic> json) =>
      _$GithubRepoDTOFromJson(json);

  factory GithubRepoDTO.fromDomain(GithubRepo _) {
    return GithubRepoDTO(
      owner: UserDTO.fromDomain(_.owner),
      name: _.name,
      description: _.description,
      stargazersCount: _.stargazersCount,
    );
  }

  GithubRepo toDomain() {
    return GithubRepo(
      owner: owner.toDomain(),
      name: name,
      description: description,
      stargazersCount: stargazersCount,
    );
  }
}
