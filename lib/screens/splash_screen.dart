import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../services/cactus_llm_service.dart';
import 'permissions_screen.dart';

/// Splash screen with app initialization and Nothing-style branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _loaderController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _loaderAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // Loader animation (line expanding)
    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loaderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loaderController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _loaderController.repeat(reverse: true);
    });

    // Initialize app
    _initializeApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Pre-warm the LLM service in background (speeds up first use)
      CactusLLMService().initialise().catchError((e) {
        debugPrint('[Splash] LLM init error (non-fatal): $e');
      });

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 2500));

      // Navigate to permissions screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const PermissionsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Still navigate even if init fails
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PermissionsScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NothFlowsColors.nothingBlack,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // App logo - NothFlows
              SvgPicture.asset(
                'assets/icons/nothflows_logo.svg',
                width: 120,
                height: 120,
                colorFilter: const ColorFilter.mode(
                  NothFlowsColors.nothingWhite,
                  BlendMode.srcIn,
                ),
              ),

              const SizedBox(height: 32),

              // App name
              Text(
                'NothFlows',
                style: NothFlowsTypography.displayMedium.copyWith(
                  color: NothFlowsColors.nothingWhite,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Smart modes for Nothing Phones',
                style: NothFlowsTypography.bodyMedium.copyWith(
                  color: NothFlowsColors.textSecondary,
                ),
              ),

              const Spacer(flex: 2),

              // Nothing-style line loader
              AnimatedBuilder(
                animation: _loaderAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 2,
                    decoration: BoxDecoration(
                      color: NothFlowsColors.borderDark,
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: Align(
                      alignment: Alignment(
                        _loaderAnimation.value * 2 - 1,
                        0,
                      ),
                      child: Container(
                        width: 32,
                        height: 2,
                        decoration: BoxDecoration(
                          color: NothFlowsColors.nothingRed.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 1),

              // Version
              Text(
                'v1.0.0',
                style: NothFlowsTypography.caption.copyWith(
                  color: NothFlowsColors.textDisabled,
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
