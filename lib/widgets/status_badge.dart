import 'package:flutter/material.dart';

import '../models/client_status.dart';

/// Small pill showing a client's status in its accent color.
///
/// [filled] draws a solid, high-visibility pill (status color background with
/// a contrast-picked text color); otherwise it's a soft tinted chip.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.dense = false,
    this.filled = false,
  });

  final ClientStatus status;
  final bool dense;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black.withValues(alpha: 0.82);

    final bg = filled ? color : color.withValues(alpha: 0.15);
    final fg = filled ? onColor : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: filled
            ? null
            : Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: dense ? 13 : 15, color: fg),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11.5 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
