import '../models/friend.dart';
import 'api_client.dart';

class FriendsService {
  final ApiClient _apiClient = ApiClient();

  FriendsService();

  List<Friend>? _cachedFriends;
  DateTime? _cachedAt;

  static const Duration _cacheDuration = Duration(seconds: 30);

  Future<List<Friend>> getFriends() async {
    if (_isCacheValid) {
      return _cachedFriends!;
    }

    return refreshFriends();
  }

  Future<List<Friend>> refreshFriends() async {
    final friends = await _apiClient.get<List<Friend>>(
      '/friends',
      parser: (data) {
        return (data as List)
            .map(
              (json) => Friend.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      },
    );

    _cachedFriends = friends;
    _cachedAt = DateTime.now();

    return friends;
  }

  bool get _isCacheValid {
    if (_cachedFriends == null || _cachedAt == null) {
      return false;
    }

    return DateTime.now().difference(_cachedAt!) < _cacheDuration;
  }

  void clearCache() {
    _cachedFriends = null;
    _cachedAt = null;
  }
}