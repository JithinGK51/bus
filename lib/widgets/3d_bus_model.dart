import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:math' show Random;

class Bus3DModel extends StatefulWidget {
  final double width;
  final double height;
  final Color busColor;
  final Color accentColor;
  final bool enableReflections;
  final bool enableShadows;
  final bool enableParticles;
  final bool enableHeadlights;

  const Bus3DModel({
    super.key,
    this.width = 280,
    this.height = 200,
    this.busColor = const Color(0xFFFFD31D), // Yellow bus color
    this.accentColor = const Color(0xFF00403C), // Teal accent color
    this.enableReflections = true,
    this.enableShadows = true,
    this.enableParticles = true,
    this.enableHeadlights = true,
  });

  @override
  State<Bus3DModel> createState() => _Bus3DModelState();
}

class _Bus3DModelState extends State<Bus3DModel> with TickerProviderStateMixin {
  // Main rotation controller
  late AnimationController _rotationController;

  // Secondary animations for enhanced 4D effects
  late AnimationController _bounceController;
  late AnimationController _headlightController;
  late AnimationController _particleController;

  // Animation values
  late Animation<double> _bounceAnimation;
  late Animation<double> _headlightAnimation;

  // Particle system for exhaust and road dust
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Create animation controller for continuous 360-degree rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Slow rotation for better effect
    )..repeat(); // Continuously repeat the animation

    // Bounce animation for suspension effect
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Repeat the bounce with a slight delay for realism
    _bounceController.repeat(reverse: true);

    // Headlight flicker animation
    _headlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _headlightAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _headlightController, curve: Curves.easeInOut),
    );

    _headlightController.repeat(reverse: true);

    // Particle animation controller
    _particleController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 50),
          )
          ..addListener(() {
            if (widget.enableParticles && mounted) {
              // Add new particles periodically
              if (_random.nextDouble() > 0.7) {
                _addParticle();
              }

              // Update existing particles
              setState(() {
                for (int i = _particles.length - 1; i >= 0; i--) {
                  _particles[i].update();
                  if (_particles[i].isExpired) {
                    _particles.removeAt(i);
                  }
                }
              });
            }
          })
          ..repeat();

    // Initialize particles
    if (widget.enableParticles) {
      for (int i = 0; i < 5; i++) {
        _addParticle();
      }
    }
  }

  void _addParticle() {
    // Add exhaust particles or road dust based on current rotation
    final angle = _rotationController.value * 2 * math.pi;
    final isBackView = angle > math.pi * 0.5 && angle < math.pi * 1.5;

    if (isBackView) {
      // Exhaust particles when viewing from back
      _particles.add(
        _Particle(
          position: Offset(widget.width * 0.2, widget.height * 0.6),
          velocity: Offset(
            _random.nextDouble() * -2 - 1,
            _random.nextDouble() * -1,
          ),
          color: Colors.grey.withOpacity(0.7),
          size: _random.nextDouble() * 4 + 2,
          lifespan: _random.nextInt(20) + 30,
        ),
      );
    } else {
      // Road dust particles when viewing from front or sides
      _particles.add(
        _Particle(
          position: Offset(
            widget.width * (0.3 + _random.nextDouble() * 0.4),
            widget.height * 0.85,
          ),
          velocity: Offset(
            _random.nextDouble() * 2 - 1,
            _random.nextDouble() * -1 - 0.5,
          ),
          color: Colors.brown.withOpacity(0.3),
          size: _random.nextDouble() * 3 + 1,
          lifespan: _random.nextInt(15) + 15,
        ),
      );
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    _headlightController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationController,
        _bounceController,
        _headlightController,
        if (widget.enableParticles) _particleController,
      ]),
      builder: (context, child) {
        // Calculate bounce offset for suspension effect
        final bounceOffset = math.sin(_bounceAnimation.value * math.pi) * 2.0;

        return Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Enhanced perspective
                ..rotateY(
                  _rotationController.value * 2 * math.pi,
                ) // Y-axis rotation (360 degrees)
                ..rotateX(
                  math.sin(_rotationController.value * 2 * math.pi) * 0.05,
                ) // Slight X tilt for realism
                ..rotateZ(
                  math.sin(_rotationController.value * 6 * math.pi) * 0.01,
                ), // Subtle Z wobble
          child: Transform.translate(
            offset: Offset(0, bounceOffset), // Apply suspension bounce
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                children: [
                  // Main bus with enhanced 3D effects
                  CustomPaint(
                    painter: Bus3DPainter(
                      busColor: widget.busColor,
                      accentColor: widget.accentColor,
                      animationValue: _rotationController.value,
                      headlightIntensity:
                          widget.enableHeadlights
                              ? _headlightAnimation.value
                              : 0.8,
                      enableReflections: widget.enableReflections,
                      enableShadows: widget.enableShadows,
                    ),
                    size: Size(widget.width, widget.height),
                  ),

                  // Particle effects (exhaust and dust)
                  if (widget.enableParticles)
                    CustomPaint(
                      painter: _ParticlePainter(particles: _particles),
                      size: Size(widget.width, widget.height),
                    ),

                  // Road reflection effect
                  if (widget.enableReflections)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: widget.height * 0.15,
                      child: IgnorePointer(
                        child: ClipRect(
                          child: Transform(
                            alignment: Alignment.topCenter,
                            transform:
                                Matrix4.identity()
                                  ..scale(
                                    1.0,
                                    -0.5,
                                  ) // Flip and scale for reflection
                                  ..translate(
                                    0.0,
                                    -widget.height * 1.3,
                                  ), // Position the reflection
                            child: Opacity(
                              opacity: 0.2,
                              child: CustomPaint(
                                painter: Bus3DPainter(
                                  busColor: widget.busColor,
                                  accentColor: widget.accentColor,
                                  animationValue: _rotationController.value,
                                  headlightIntensity:
                                      widget.enableHeadlights
                                          ? _headlightAnimation.value
                                          : 0.8,
                                  enableReflections: false,
                                  enableShadows: false,
                                  isReflection: true,
                                ),
                                size: Size(widget.width, widget.height),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class Bus3DPainter extends CustomPainter {
  final Color busColor;
  final Color accentColor;
  final double animationValue;
  final double headlightIntensity;
  final bool enableReflections;
  final bool enableShadows;
  final bool isReflection;

  Bus3DPainter({
    required this.busColor,
    required this.accentColor,
    required this.animationValue,
    this.headlightIntensity = 1.0,
    this.enableReflections = true,
    this.enableShadows = true,
    this.isReflection = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Calculate current angle for lighting effects
    final angle = animationValue * 2 * math.pi;

    // We'll create paints as needed for each component

    // Detail paint for accents and details
    // We'll use this for the text on the bus

    final windowPaint =
        Paint()
          ..color = Color.lerp(accentColor, Colors.black, 0.7)!
          ..style = PaintingStyle.fill;

    final wheelPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;

    final highlightPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.fill;

    // Shadow paint is now created inline with the gradient shader

    // Draw ground shadow with 3D perspective
    if (enableShadows && !isReflection) {
      // Calculate shadow position based on rotation angle
      final angle = animationValue * 2 * math.pi;
      final shadowOffsetX = math.sin(angle) * width * 0.1;

      final shadowPath =
          Path()..addOval(
            Rect.fromCenter(
              center: Offset(width * 0.5 + shadowOffsetX, height * 0.95),
              width:
                  width *
                  (0.8 -
                      (math.cos(angle) * 0.2)
                          .abs()), // Narrow shadow when viewing from side
              height: height * 0.1,
            ),
          );

      // Create gradient shadow for more realistic effect
      final shadowGradient = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.0)],
      );

      canvas.drawPath(
        shadowPath,
        Paint()
          ..shader = shadowGradient.createShader(
            Rect.fromCenter(
              center: Offset(width * 0.5 + shadowOffsetX, height * 0.95),
              width: width * 0.8,
              height: height * 0.1,
            ),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Calculate lighting based on rotation angle
    final frontLightFactor = math.max(
      0,
      math.cos(angle),
    ); // Brightest when viewing front

    // Draw 3D bus body with multiple parts for better depth

    // 1. Bottom chassis (darker)
    final chassisPath = Path();
    chassisPath.moveTo(width * 0.05, height * 0.6);
    chassisPath.lineTo(width * 0.95, height * 0.6);
    chassisPath.lineTo(width * 0.95, height * 0.7);
    chassisPath.lineTo(width * 0.05, height * 0.7);
    chassisPath.close();

    final chassisPaint =
        Paint()
          ..color = Color.lerp(busColor, Colors.black, 0.5)!
          ..style = PaintingStyle.fill;

    canvas.drawPath(chassisPath, chassisPaint);

    // 2. Main bus body with gradient
    final bodyPath = Path();

    // Main body shape
    bodyPath.moveTo(width * 0.1, height * 0.6);
    bodyPath.lineTo(width * 0.1, height * 0.3);
    bodyPath.quadraticBezierTo(
      width * 0.15,
      height * 0.2,
      width * 0.25,
      height * 0.2,
    );
    bodyPath.lineTo(width * 0.9, height * 0.2);
    bodyPath.quadraticBezierTo(
      width * 0.95,
      height * 0.25,
      width * 0.95,
      height * 0.35,
    );
    bodyPath.lineTo(width * 0.95, height * 0.6);
    bodyPath.lineTo(width * 0.1, height * 0.6);
    bodyPath.close();

    // Enhanced body paint with gradient
    final bodyGradientPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(width * 0.5, 0),
            Offset(width * 0.5, height * 0.6),
            [
              Color.lerp(busColor, Colors.white, 0.15 * frontLightFactor)!,
              busColor,
              Color.lerp(busColor, Colors.black, 0.2)!,
            ],
            [0.0, 0.7, 1.0],
          );

    canvas.drawPath(bodyPath, bodyGradientPaint);

    // 3. Add highlight strip along the side for 3D effect
    if (!isReflection) {
      final highlightPath = Path();
      highlightPath.moveTo(width * 0.1, height * 0.35);
      highlightPath.lineTo(width * 0.95, height * 0.35);
      highlightPath.lineTo(width * 0.95, height * 0.38);
      highlightPath.lineTo(width * 0.1, height * 0.38);
      highlightPath.close();

      final highlightPaint =
          Paint()
            ..color = Color.lerp(busColor, Colors.white, 0.3)!
            ..style = PaintingStyle.fill;

      canvas.drawPath(highlightPath, highlightPaint);
    }

    // 4. Add roof with slight curve for 3D effect
    final roofPath = Path();
    roofPath.moveTo(width * 0.15, height * 0.2);
    roofPath.quadraticBezierTo(
      width * 0.5,
      height * 0.15, // Curve upward for 3D effect
      width * 0.85,
      height * 0.2,
    );
    roofPath.lineTo(width * 0.9, height * 0.2);
    roofPath.quadraticBezierTo(
      width * 0.5,
      height * 0.19, // Slight curve for realism
      width * 0.25,
      height * 0.2,
    );
    roofPath.close();

    final roofPaint =
        Paint()
          ..color = Color.lerp(busColor, Colors.white, 0.2)!
          ..style = PaintingStyle.fill;

    canvas.drawPath(roofPath, roofPaint);

    // Draw windows
    final windowSpacing = width * 0.02;
    final windowWidth = width * 0.12;
    final windowHeight = height * 0.15;
    final windowTop = height * 0.25;

    // Front window (driver)
    final frontWindowPath = Path();
    frontWindowPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.25, windowTop, windowWidth * 1.2, windowHeight),
        const Radius.circular(5),
      ),
    );
    canvas.drawPath(frontWindowPath, windowPaint);

    // Side windows
    for (int i = 0; i < 4; i++) {
      final windowPath = Path();
      windowPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            width * 0.4 + (windowWidth + windowSpacing) * i,
            windowTop,
            windowWidth,
            windowHeight,
          ),
          const Radius.circular(5),
        ),
      );
      canvas.drawPath(windowPath, windowPaint);
    }

    // Draw wheels
    final wheelRadius = height * 0.12;
    final frontWheelCenter = Offset(width * 0.25, height * 0.75);
    final rearWheelCenter = Offset(width * 0.75, height * 0.75);

    // Wheel arches
    final archPaint =
        Paint()
          ..color = Color.lerp(busColor, Colors.black, 0.2)!
          ..style = PaintingStyle.fill;

    final frontArchPath = Path();
    frontArchPath.addArc(
      Rect.fromCenter(
        center: frontWheelCenter,
        width: wheelRadius * 2.4,
        height: wheelRadius * 2.4,
      ),
      math.pi,
      math.pi,
    );
    canvas.drawPath(frontArchPath, archPaint);

    final rearArchPath = Path();
    rearArchPath.addArc(
      Rect.fromCenter(
        center: rearWheelCenter,
        width: wheelRadius * 2.4,
        height: wheelRadius * 2.4,
      ),
      math.pi,
      math.pi,
    );
    canvas.drawPath(rearArchPath, archPaint);

    // Wheels
    canvas.drawCircle(frontWheelCenter, wheelRadius, wheelPaint);
    canvas.drawCircle(rearWheelCenter, wheelRadius, wheelPaint);

    // Wheel hubs
    canvas.drawCircle(frontWheelCenter, wheelRadius * 0.4, highlightPaint);
    canvas.drawCircle(rearWheelCenter, wheelRadius * 0.4, highlightPaint);

    // Draw enhanced 3D headlights with glow effect
    if (!isReflection) {
      // Headlight base
      final headlightBasePaint =
          Paint()
            ..color = Colors.grey.shade300
            ..style = PaintingStyle.fill;

      // Headlight lens
      final headlightPaint =
          Paint()
            ..color = Colors.white.withOpacity(headlightIntensity)
            ..style = PaintingStyle.fill;

      // Left headlight with 3D effect
      canvas.drawCircle(
        Offset(width * 0.15, height * 0.35),
        height * 0.055,
        headlightBasePaint,
      );

      canvas.drawCircle(
        Offset(width * 0.15, height * 0.35),
        height * 0.05,
        headlightPaint,
      );

      // Right headlight with 3D effect
      canvas.drawCircle(
        Offset(width * 0.15, height * 0.45),
        height * 0.055,
        headlightBasePaint,
      );

      canvas.drawCircle(
        Offset(width * 0.15, height * 0.45),
        height * 0.05,
        headlightPaint,
      );

      // Add headlight glow when facing front
      if (math.cos(angle) > 0.7 && headlightIntensity > 0.8) {
        final glowPaint =
            Paint()
              ..shader = ui.Gradient.radial(
                Offset(width * 0.15, height * 0.35),
                height * 0.15,
                [
                  Colors.white.withOpacity(0.7 * headlightIntensity),
                  Colors.white.withOpacity(0.0),
                ],
              )
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

        canvas.drawCircle(
          Offset(width * 0.15, height * 0.35),
          height * 0.15,
          glowPaint,
        );

        canvas.drawCircle(
          Offset(width * 0.15, height * 0.45),
          height * 0.15,
          glowPaint,
        );

        // Add light beam effect
        final beamPath = Path();
        beamPath.moveTo(width * 0.15, height * 0.35);
        beamPath.lineTo(width * -0.2, height * 0.2);
        beamPath.lineTo(width * -0.2, height * 0.5);
        beamPath.close();

        final beamPaint =
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(width * 0.15, height * 0.35),
                Offset(width * -0.2, height * 0.35),
                [
                  Colors.white.withOpacity(0.4 * headlightIntensity),
                  Colors.white.withOpacity(0.0),
                ],
              );

        canvas.drawPath(beamPath, beamPaint);
      }
    }

    // Draw enhanced 3D taillights with glow
    if (!isReflection) {
      // Taillight base
      final taillightBasePaint =
          Paint()
            ..color = Colors.red.shade900
            ..style = PaintingStyle.fill;

      // Taillight lens
      final taillightPaint =
          Paint()
            ..color = Colors.red.withOpacity(0.9)
            ..style = PaintingStyle.fill;

      // Upper taillight
      final upperTaillight = RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.9, height * 0.3, width * 0.05, height * 0.1),
        const Radius.circular(2),
      );

      // Lower taillight
      final lowerTaillight = RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.9, height * 0.45, width * 0.05, height * 0.1),
        const Radius.circular(2),
      );

      // Draw taillight bases (slightly larger for 3D effect)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            width * 0.895,
            height * 0.295,
            width * 0.06,
            height * 0.11,
          ),
          const Radius.circular(3),
        ),
        taillightBasePaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            width * 0.895,
            height * 0.445,
            width * 0.06,
            height * 0.11,
          ),
          const Radius.circular(3),
        ),
        taillightBasePaint,
      );

      // Draw taillight lenses
      canvas.drawRRect(upperTaillight, taillightPaint);
      canvas.drawRRect(lowerTaillight, taillightPaint);

      // Add taillight glow when facing back
      if (math.cos(angle) < -0.7) {
        final glowPaint =
            Paint()
              ..shader = ui.Gradient.radial(
                Offset(width * 0.925, height * 0.35),
                height * 0.15,
                [Colors.red.withOpacity(0.6), Colors.red.withOpacity(0.0)],
              )
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

        canvas.drawCircle(
          Offset(width * 0.925, height * 0.35),
          height * 0.1,
          glowPaint,
        );

        canvas.drawCircle(
          Offset(width * 0.925, height * 0.5),
          height * 0.1,
          glowPaint,
        );
      }
    }

    // Draw speed lines based on animation value
    if (animationValue > 0.5 && animationValue < 0.75) {
      final speedLinesPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

      for (int i = 0; i < 5; i++) {
        final lineLength = width * (0.3 - i * 0.05);
        canvas.drawLine(
          Offset(width * 0.05, height * (0.3 + i * 0.07)),
          Offset(width * 0.05 - lineLength, height * (0.3 + i * 0.07)),
          speedLinesPaint,
        );
      }
    }

    // Draw "TUMKURU" text on the side of the bus
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'TUMKURU',
        style: TextStyle(
          color: accentColor,
          fontSize: height * 0.1,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(width * 0.4, height * 0.45));
  }

  @override
  bool shouldRepaint(covariant Bus3DPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.busColor != busColor ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Particle class for exhaust smoke and road dust effects
class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  int lifespan;
  int age = 0;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifespan,
  });

  bool get isExpired => age >= lifespan;

  double get opacity => 1.0 - (age / lifespan);

  void update() {
    position = position + velocity;
    velocity = velocity.scale(0.95, 0.95); // Slow down over time
    age++;
  }
}

/// Painter for rendering particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint =
          Paint()
            ..color = particle.color.withOpacity(particle.opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true; // Always repaint as particles are constantly moving
  }
}
