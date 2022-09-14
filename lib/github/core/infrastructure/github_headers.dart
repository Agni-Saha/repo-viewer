import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_headers.freezed.dart';
part 'github_headers.g.dart';

// ^ This class contains
// ^ ...eTag which we can use to check if there have been server updates (calling from local storage if not)
// ^ ...link from which we can extract the last page number when scrolling in our lists
// ^ converts to and from JSON for local storage

@freezed
class GithubHeaders with _$GithubHeaders {
  const GithubHeaders._();
  const factory GithubHeaders({
    String? eTag,
    PaginationLink? link,
  }) = _GithubHeaders;

  // This constructor takes a Response object from dio, then constructs a GithubHeader object from it
  factory GithubHeaders.parse(Response response) {
    // We get the spelling of key values 'Link' and 'Etag' testing queries via the REST extension
    final link = response.headers.map['Link']?[0];
    return GithubHeaders(
      eTag: response.headers.map['Etag']?[0],
      link: link == null
          ? null
          // See factory constructor for PaginationLink class
          : PaginationLink.parse(
              // The content of the Link field from where we want to extract the max page (converted to a list)
              link.split(','),
              // The URI from our own query for use if there is nomax page in the above
              requestUrl: response.requestOptions.uri.toString(),
            ),
    );
  }

  // We need to be able to convert this class to and from JSON to store it in our Sembast database
  factory GithubHeaders.fromJson(Map<String, dynamic> json) =>
      _$GithubHeadersFromJson(json);
}

// Link format for reference
// & link: <https://api.github.com/user/starred?page=2>; rel="next", <https://api.github.com/user/starred?page=8; rel="last"

// ^ Parses link from API and extracts max page number into field

@freezed
class PaginationLink with _$PaginationLink {
  const PaginationLink._();
  const factory PaginationLink({
    required int maxPage,
  }) = _PaginationLink;

  // If we are already on the last page, the link will not contain 'rel="last"', therefore we pass the currentUrl
  // into this method and extract the 'page' value from that instead
  factory PaginationLink.parse(List<String> values,
      {required String requestUrl}) {
    return PaginationLink(
      // We call a method to return our max page number
      maxPage: _extractPageNumber(
        values.firstWhere(
          (e) => e.contains('rel="last"'),
          orElse: () => requestUrl,
        ),
      ),
    );
  }

  static int _extractPageNumber(String value) {
    // Get the expression by googling 'url regex javascript'. We prefix the string with 'r' to ensure the
    // backslashes are processed as part of the string
    final uriString = RegExp(
            r'[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)')
        .stringMatch(value);
    return int.parse(Uri.parse(uriString!).queryParameters['page']!);
  }

  factory PaginationLink.fromJson(Map<String, dynamic> json) =>
      _$PaginationLinkFromJson(json);
}
