import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ksrtc_users/widgets/3d_bus_model.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  // Logo animations
  late Animation<double> _logoFadeInAnimation;
  late Animation<double> _logoScaleAnimation;

  // Text animations
  late Animation<double> _textFadeInAnimation;
  late Animation<Offset> _textSlideAnimation;

  // Credits animations
  late Animation<double> _creditsFadeInAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Main background fade in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Main background scale animation
    _scaleAnimation = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Subtle rotation animation
    _rotationAnimation = Tween<double>(begin: -0.02, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Logo animations - start after background
    _logoFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Text animations - start after logo
    _textFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    // Credits animations - last to appear
    _creditsFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animation
    _animationController.forward();

    // Navigate to next screen after 7 seconds
    Timer(const Duration(seconds: 7), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => widget.nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var fadeAnimation = animation.drive(tween);

            return FadeTransition(opacity: fadeAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00403C), // Teal color matching the logo
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Animated background
              FadeTransition(
                opacity: _fadeInAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF00403C), // Teal color matching the logo
                            Color(
                              0xFF002B28,
                            ), // Darker teal for gradient effect
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content container
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with animation
                    FadeTransition(
                      opacity: _logoFadeInAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Container(
                          width: 320,
                          height: 320,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF00403C,
                            ), // Same as background
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFD31D,
                                ).withOpacity(0.3), // Yellow glow
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          // Enhanced 3D/4D Bus Model
                          child: const Bus3DModel(
                            width: 280,
                            height: 200,
                            busColor: Color(0xFFFFD31D), // Yellow bus color
                            accentColor: Color(0xFF00403C), // Teal accent color
                            enableReflections: true,
                            enableShadows: true,
                            enableParticles: true,
                            enableHeadlights: true,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App name with animation
                    FadeTransition(
                      opacity: _textFadeInAnimation,
                      child: SlideTransition(
                        position: _textSlideAnimation,
                        child: const Text(
                          'TUMKURU',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD31D), // Exact yellow from logo
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 0),

                    // App tagline with animation
                    FadeTransition(
                      opacity: _textFadeInAnimation,
                      child: SlideTransition(
                        position: _textSlideAnimation,
                        child: const Text(
                          'bus',
                          style: TextStyle(
                            fontSize: 32,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFFFD31D), // Exact yellow from logo
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Credits with animation
                    FadeTransition(
                      opacity: _creditsFadeInAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Developed by',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // CrafZio logo/text
                              const Text(
                                'CrafZio',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(
                                    0xFFFFD31D,
                                  ), // Exact yellow from logo
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 18,
                                width: 2,
                                color: Colors.white30,
                              ),
                              const SizedBox(width: 12),
                              // Digital Tumkuru logo/text
                              const Text(
                                'Solution',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(
                                    0xFFFFD31D,
                                  ), // Exact yellow from logo
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
