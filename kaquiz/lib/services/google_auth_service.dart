import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> initialize() async {
    await _googleSignIn.initialize();
  }

  Future<String?> signIn() async {
    try {
      final GoogleSignInAccount user = await GoogleSignIn.instance.authenticate();

      final authentication = user.authentication;

      return authentication.idToken;
    } on GoogleSignInException catch (e) {
      print('Google Sign-In error: ${e.code}');
      return null;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

}