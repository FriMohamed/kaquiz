import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kaquiz/app/theme/app_colors.dart';
import 'package:kaquiz/services/token_storage_service.dart';

class AuthStartupScreen extends StatefulWidget {
  const AuthStartupScreen({super.key});

  @override
  State<AuthStartupScreen> createState() => _AuthStartupScreenState();
}

class _AuthStartupScreenState extends State<AuthStartupScreen>
    with SingleTickerProviderStateMixin {
  final TokenStorageService _tokenStorage = TokenStorageService();

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _verticalAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _verticalAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: -30.0,
          end: 8.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 8.0,
          end: -3.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -3.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
    ]).animate(_controller);

    _checkAuthentication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    final token = await _tokenStorage.getAccessToken();

    if (!mounted) return;

    if (token != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _verticalAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: SvgPicture.asset('assets/logo.svg', width: 78, height: 108),
        ),
      ),
    );
  }
}
