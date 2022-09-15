import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_headers.freezed.dart';
part 'github_headers.g.dart';

/* 
CORE: 
Whenever we make a request, we need to check two things :- whether the data we
have already cached is up-to-date or not, and how many more pages of data can
we recieve from server. This is the placeholder class for eTag and link header
that achieve exactly those purposes.

We can get the eTag simply from the header but getting the number of pages is quite
complicated as we have to extract that from the link header. And that's why we have
created a seperate class that has the maxPages field and extracts that from the link
header.
*/

@freezed
class GithubHeaders with _$GithubHeaders {
  const GithubHeaders._();
  const factory GithubHeaders({
    String? eTag,
    PaginationLink? link,
  }) = _GithubHeaders;

  factory GithubHeaders.parse(Response response) {
    final link = response.headers.map['Link']?[0];
    return GithubHeaders(
      eTag: response.headers.map['Etag']?[0],
      link: link == null
          ? null
          : PaginationLink.parse(
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
      r'[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)',
    ).stringMatch(value);
    return int.parse(
      Uri.parse(uriString!).queryParameters['page']!,
    );
  }

  factory PaginationLink.fromJson(Map<String, dynamic> json) =>
      _$PaginationLinkFromJson(json);
}
