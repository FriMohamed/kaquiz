import 'api_client.dart';
import 'token_storage_service.dart';

class AuthService {
  final ApiClient apiClient = ApiClient();
  final TokenStorageService tokenStorage = TokenStorageService();

  AuthService();

  Future<String> loginWithGoogle(String idToken) async {
    final accessToken = await apiClient.post<String>(
      '/auth',
      body: {'id_token': idToken},
      parser: (data) {
        return (data as Map<String, dynamic>)['access_token'] as String;
      },
    );

    await tokenStorage.saveAccessToken(accessToken);

    return accessToken;
  }

  Future<void> logout() async {
    await tokenStorage.deleteAccessToken();
  }
}
