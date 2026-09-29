import 'package:kaquiz/models/friend_location.dart';

class Friend {
  final int id;
  final String name;
  final String avatar;
  final FriendLocation? location;

  const Friend({
    required this.id,
    required this.name,
    required this.avatar,
    this.location,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    final locationJson = json['location'];

    return Friend(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      location: locationJson is Map<String, dynamic>
          ? FriendLocation.fromJson(locationJson)
          : null,
    );
  }
}