import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The app's signature logo: a gradient rounded tile with a diamond glyph and
/// a soft glow. Reused on the splash, login and hero surfaces so the brand
/// reads consistently everywhere.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 72,
    this.glow = true,
  });

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.royal.withValues(alpha: 0.45),
                  blurRadius: size * 0.5,
                  offset: Offset(0, size * 0.18),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.diamond_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

/// Small gold "VIP" pill used to signal the premium tier.
class VipTag extends StatelessWidget {
  const VipTag({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        'VIP',
        style: TextStyle(
          color: AppColors.onGold,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 10 : 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
