
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kaquiz/app/theme/app_colors.dart';
import 'package:kaquiz/services/auth_service.dart';
import 'package:kaquiz/services/google_auth_service.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleAuthService.initialize();
    } catch (e) {
      debugPrint('Google initialization error: $e');
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Sign in with Google
      final idToken = await _googleAuthService.signIn();

      // User cancelled Google sign-in
      if (idToken == null) {
        return;
      }

      // 2. Send Google ID token to your backend
      await _authService.loginWithGoogle(idToken);

      if (!mounted) return;
      context.go('/home');

      // 3. Login successful
      // Navigate to your home screen here.
      //
      // Example:
      //
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(
      //     builder: (_) => const HomeScreen(),
      //   ),
      // );
    } catch (e) {
      debugPrint('#Login error#: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to sign in. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/logo.svg',
                            width: 78,
                            height: 108,
                          ),

                          const SizedBox(height: 24),

                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: -1.68,
                                color: AppColors.foreground,
                              ),
                              children: [
                                TextSpan(text: 'Kaqui'),
                                TextSpan(
                                  text: 'z',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Know where your friends are.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              height: 1.5,
                              color: AppColors.muted,
                            ),
                          ),

                          const SizedBox(height: 48),

                          _GoogleButton(
                            isLoading: _isLoading,
                            onPressed: _loginWithGoogle,
                          ),

                          const SizedBox(height: 16),

                          const _Terms(),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: _PageDots(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _GoogleButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: const BorderSide(
            color: AppColors.border,
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/google_icon.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Terms extends StatelessWidget {
  const _Terms();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          height: 1.5,
          color: AppColors.subtle,
        ),
        children: [
          const TextSpan(
            text: 'By continuing you agree to our ',
          ),
          TextSpan(
            text: 'Terms',
            style: const TextStyle(
              color: AppColors.muted,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO
              },
          ),
          const TextSpan(text: ' & '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: AppColors.muted,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO
              },
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(),
        const SizedBox(width: 8),
        _dot(),
        const SizedBox(width: 8),
        _dot(),
      ],
    );
  }

  Widget _dot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
