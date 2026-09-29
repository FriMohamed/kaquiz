import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> initialize() async {
    await _googleSignIn.initialize(
      serverClientId:
          '809969609969-8bvfm2sj692otpp9lvdli03ti4gooai0.apps.googleusercontent.com',
    );
  }

  Future<String?> signIn() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.authenticate();
      if (user == null) return null;

      final GoogleSignInAuthentication authentication =
          await user.authentication;
      return authentication.idToken;
    } catch (e, stackTrace) {
      // Print the full exception details
      print('--- GOOGLE SIGN-IN ERROR DETAILS ---');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('StackTrace: $stackTrace');
      print('------------------------------------');
      return null;
    }
  }
}
