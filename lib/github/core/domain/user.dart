import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const User._();
  const factory User({
    required String name,
    required String avatarUrl,
  }) = _User;

  // modifies url to request 64 pixel image as determined from API documentation
  String get avatarUrlSmall => '$avatarUrl&s=64';
}
