import 'package:flutter/material.dart';
import 'package:ksrtc_users/theme/app_theme.dart';

enum PasswordStrength { weak, medium, strong, veryStrong }

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  PasswordStrength _calculatePasswordStrength() {
    if (password.isEmpty) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Complexity checks
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Determine strength based on score
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  String _getStrengthText() {
    switch (_calculatePasswordStrength()) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  Color _getStrengthColor() {
    switch (_calculatePasswordStrength()) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
      case PasswordStrength.veryStrong:
        return Colors.green.shade800;
    }
  }

  double _getStrengthPercent() {
    switch (_calculatePasswordStrength()) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _getStrengthPercent(),
                  backgroundColor: Colors.grey.shade300,
                  color: _getStrengthColor(),
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getStrengthText(),
              style: TextStyle(
                color: _getStrengthColor(),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Use 8+ characters with a mix of letters, numbers & symbols',
          style: TextStyle(fontSize: 11, color: AppTheme.textGrey),
        ),
      ],
    );
  }
}
