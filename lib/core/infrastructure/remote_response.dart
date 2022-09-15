import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_response.freezed.dart';

/*
CORE:
These are the variants of the API response of getting the repositories. We are only focusing
on three cases - if the data that we already have is up-to-date with the server (304 status),
if the data we get is brand new (200 status), or if the error that we get is a no-connection
error.
*/

@freezed
class RemoteResponse<T> with _$RemoteResponse<T> {
  const RemoteResponse._();

  // will use data from local storage but will also present popup saying info may be outdated
  const factory RemoteResponse.noConnection() = _NoConnection<T>;

  // will use data from local storage
  const factory RemoteResponse.notModified({
    required int maxPage,
  }) = _NotModified<T>;

  // will perform API call
  const factory RemoteResponse.withNewData(
    T data, {
    required int maxPage,
  }) = _WithNewData<T>;
}
