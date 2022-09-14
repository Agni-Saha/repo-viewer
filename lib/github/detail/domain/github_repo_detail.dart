import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_repo_detail.freezed.dart';

// we'll be getting the fields for this dataobject from different sources. The DTO serves the local cache. The api is
// not going to be able to get all these fields from just 1 endpoint

@freezed
class GithubRepoDetail with _$GithubRepoDetail {
  const GithubRepoDetail._();
  const factory GithubRepoDetail({
    // the full name is specified in the endpoint URL
    required String fullName,
    required String html,
    required bool starred,
  }) = _GithubRepoDetail;
}
