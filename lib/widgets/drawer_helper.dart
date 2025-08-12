import 'package:flutter/material.dart';
import 'package:ksrtc_users/widgets/animated_drawer.dart';

class DrawerHelper {
  static Future<T?> showAnimatedDrawer<T>({
    required BuildContext context,
    required Widget drawer,
    bool isRightSide = false,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeOut,
    double widthPercent = 0.75,
    VoidCallback? onClose,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return AnimatedDrawer(
            isRightSide: isRightSide,
            duration: duration,
            curve: curve,
            widthPercent: widthPercent,
            onClose: onClose,
            child: drawer,
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
