class FriendLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const FriendLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory FriendLocation.fromJson(Map<String, dynamic> json) {
    return FriendLocation(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      timestamp: DateTime.parse(json['timestamp'].toString()),
    );
  }
}