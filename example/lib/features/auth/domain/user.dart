// For domain classes, it's a VERY good idea to implement value equality, so
// less rebuilds are done when multiple messages or domain objects have the
// same value.
//
// Since immutability is also a must to make your code more resilient againts
// logic bugs, a `copyWith` implementation also is good.
//
// And since remote services are very common, a serializable class is also
// interest.
//
// We recommend the usage of https://pub.dev/packages/dart_mappable, since it
// delivers all those points, without any drawbacks.

// This is an anaemic model that will represent an authenticated user
// in our application
import 'package:dart_mappable/dart_mappable.dart';

part 'user.mapper.dart';

@MappableClass()
final class User with UserMappable {
  const User({required this.id, required this.name, required this.photoUrl});
  factory User.fromMap(Map<String, dynamic> map) => UserMapper.fromMap(map);
  factory User.fromJson(String json) => UserMapper.fromJson(json);

  final String id;
  final String name;
  final String photoUrl;
}
