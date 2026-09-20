import 'package:flutter/material.dart';
import 'package:lurc/theme/lurc_theme.dart';

class LurcMark extends StatelessWidget {
  const new({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      image: true,
      label: 'Lurc logo',
      child: CustomPaint(
        size: Size.square(size),
        painter: _LurcMarkPainter(
          leftColor: isDark ? LurcColors.offWhite : LurcColors.navy,
        ),
      ),
    );
  }
}

class _LurcMarkPainter extends CustomPainter {
  const new({required this.leftColor});

  final Color leftColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 512, size.height / 512);

    final left = Path()
      ..moveTo(252, 92)
      ..arcToPoint(
        const Offset(252, 372),
        radius: const Radius.circular(140),
        clockwise: false,
      )
      ..close();

    final right = Path()
      ..moveTo(260, 140)
      ..arcToPoint(
        const Offset(260, 420),
        radius: const Radius.circular(140),
      )
      ..close();

    canvas
      ..drawPath(left, Paint()..color = leftColor)
      ..drawPath(right, Paint()..color = LurcColors.emerald)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _LurcMarkPainter oldDelegate) =>
      oldDelegate.leftColor != leftColor;
}
