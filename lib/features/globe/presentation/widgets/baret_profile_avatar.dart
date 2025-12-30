import 'package:flutter/material.dart';

/// Custom Baret-themed profile avatar with bracket design inspired by the logo
class BaretProfileAvatar extends StatelessWidget {
  final String name;
  final Color backgroundColor;
  final double size;
  final double borderWidth;

  const BaretProfileAvatar({
    super.key,
    required this.name,
    required this.backgroundColor,
    this.size = 32,
    this.borderWidth = 1.5,
  });

  /// Get initials from name (first letter of first and last name)
  String _getInitials() {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.6, size * 0.6),
          painter: _BaretBracketPainter(
            initials: initials,
            textColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Custom painter to draw the Baret-style brackets around initials
class _BaretBracketPainter extends CustomPainter {
  final String initials;
  final Color textColor;

  _BaretBracketPainter({
    required this.initials,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = textColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw brackets inspired by Baret logo
    final bracketWidth = size.width * 0.15;
    final bracketHeight = size.height * 0.8;
    final bracketTop = (size.height - bracketHeight) / 2;

    // Left bracket (
    final leftBracketPath = Path()
      ..moveTo(bracketWidth * 1.5, bracketTop)
      ..quadraticBezierTo(
        0,
        size.height / 2,
        bracketWidth * 1.5,
        bracketTop + bracketHeight,
      );
    canvas.drawPath(leftBracketPath, paint);

    // Right bracket )
    final rightBracketPath = Path()
      ..moveTo(size.width - bracketWidth * 1.5, bracketTop)
      ..quadraticBezierTo(
        size.width,
        size.height / 2,
        size.width - bracketWidth * 1.5,
        bracketTop + bracketHeight,
      );
    canvas.drawPath(rightBracketPath, paint);

    // Draw initials in the center
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: textColor,
          fontSize: size.width * 0.35,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(_BaretBracketPainter oldDelegate) {
    return oldDelegate.initials != initials || oldDelegate.textColor != textColor;
  }
}
