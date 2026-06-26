import 'package:flutter/material.dart';

import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/core/widgets/glass_panel.dart';
class WatchActivityRing extends StatelessWidget {
  const WatchActivityRing({
    super.key,
    this.size = 36,
    this.progress = 0.72,
    this.color = AppTheme.activityGreen,
  });

  final double size;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.11;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final bg = Paint()
      ..color = AppTheme.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.28318, false, bg);
    canvas.drawArc(rect, -1.5708, 6.28318 * progress.clamp(0.05, 1.0), false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class GeenGreenLogo extends StatelessWidget {
  const GeenGreenLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        WatchActivityRing(size: compact ? 28 : 36, progress: compact ? 0.65 : 0.78),
        SizedBox(width: compact ? 8 : 12),
        Text(
          'GEENGREEN',
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontFamilyFallback: AppTheme.fontFamilyFallback,
            fontSize: compact ? 15 : 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: compact ? 0.5 : 1.2,
          ),
        ),
      ],
    );
  }
}

class WatchMetric extends StatelessWidget {
  const WatchMetric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.accent = AppTheme.activityGreen,
  });

  final String label;
  final String value;
  final String? unit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontFamilyFallback: AppTheme.fontFamilyFallback,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Text(
                unit!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Staged scan overlay — feels fast even when Render cold-starts.
class WatchScanOverlay extends StatelessWidget {
  const WatchScanOverlay({
    super.key,
    required this.stage,
    required this.progress,
    this.elapsedSec = 0,
    this.onCancel,
  });

  final String stage;
  final double progress;
  final int elapsedSec;
  final VoidCallback? onCancel;

  static const stages = [
    'Connecting',
    'Mapping route',
    'Syncing signals',
    'Optimizing green wave',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: GlassPanel(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
          borderRadius: AppTheme.radiusLg,
          child: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.04, 0.98),
                          strokeWidth: 6,
                          backgroundColor: AppTheme.surfaceElevated,
                          color: AppTheme.activityGreen,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      WatchActivityRing(size: 52, progress: progress.clamp(0.1, 1.0)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  stage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  elapsedSec > 12
                      ? 'Waking server — first load can take ~30s'
                      : 'Finding your greenest commute',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
                if (onCancel != null) ...[
                  const SizedBox(height: 16),
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WatchCornerButton extends StatelessWidget {
  const WatchCornerButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppTheme.activityGreen),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
