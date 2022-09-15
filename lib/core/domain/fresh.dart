import 'package:freezed_annotation/freezed_annotation.dart';

part 'fresh.freezed.dart';

/*
This class makes sure whether the data is fresh or not (i.e., whether we need
to display that flash popup whenever we are offline, because when we are offline
we have no way to know whether these data are up-to-date with server data or not).
*/

@freezed
class Fresh<T> with _$Fresh<T> {
  const Fresh._();
  const factory Fresh({
    required T entity,
    required bool isFresh,
    bool? isNextPageAvailable,
  }) = _Fresh<T>;

  factory Fresh.yes(
    T entity, {
    bool? isNextPageAvailable,
  }) =>
      Fresh(
        entity: entity,
        isFresh: true,
        isNextPageAvailable: isNextPageAvailable,
      );

  factory Fresh.no(
    T entity, {
    bool? isNextPageAvailable,
  }) =>
      Fresh(
        entity: entity,
        isFresh: false,
        isNextPageAvailable: isNextPageAvailable,
      );
}
