import 'package:flutter/material.dart';

class AnimatedDrawer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool isRightSide;
  final double widthPercent;
  final VoidCallback? onClose;

  const AnimatedDrawer({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOut,
    this.isRightSide = false,
    this.widthPercent = 0.75,
    this.onClose,
  }) : super(key: key);

  @override
  State<AnimatedDrawer> createState() => _AnimatedDrawerState();
}

class _AnimatedDrawerState extends State<AnimatedDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(_animation);

    // Open drawer immediately
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeDrawer() async {
    await _controller.reverse();
    if (widget.onClose != null) {
      widget.onClose!();
    }
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * widget.widthPercent;

    return WillPopScope(
      onWillPop: () async {
        _closeDrawer();
        return false;
      },
      child: Stack(
        children: [
          // Semi-transparent background
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Opacity(
                opacity: _animation.value * 0.5,
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                  ),
                ),
              );
            },
          ),

          // Drawer content with animation
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Positioned(
                left:
                    widget.isRightSide
                        ? null
                        : (_animation.value - 1) * drawerWidth,
                right:
                    widget.isRightSide
                        ? (_animation.value - 1) * drawerWidth
                        : null,
                top: 0,
                bottom: 0,
                width: drawerWidth,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment:
                      widget.isRightSide
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                  child: widget.child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
