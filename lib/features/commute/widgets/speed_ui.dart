import 'package:flutter/material.dart';

import 'package:london_runner/core/services/ui_sound.dart';
import 'package:london_runner/core/theme/app_theme.dart';
class SpeedGoButton extends StatelessWidget {
  const SpeedGoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel = 'Starting…',
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: loading
            ? null
            : () {
                UiSound.instance.tap();
                onPressed?.call();
              },
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.runGreen,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppTheme.runGreen.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        ),
        child: Text(
          loading ? loadingLabel : label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.2),
        ),
      ),
    );
  }
}

class SpeedTimeChips extends StatelessWidget {
  const SpeedTimeChips({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onCustom,
  });

  final TimeOfDay selected;
  final ValueChanged<TimeOfDay> onSelected;
  final VoidCallback onCustom;

  static const _presets = [
    TimeOfDay(hour: 8, minute: 30),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 18, minute: 0),
  ];

  @override
  Widget build(BuildContext context) {
    final fmt = MaterialLocalizations.of(context);
    final isPreset = _presets.any((t) => t.hour == selected.hour && t.minute == selected.minute);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._presets.map((t) {
          final active = t.hour == selected.hour && t.minute == selected.minute;
          return _Chip(
            label: fmt.formatTimeOfDay(t, alwaysUse24HourFormat: false),
            active: active,
            onTap: () {
              UiSound.instance.tap();
              onSelected(t);
            },
          );
        }),
        _Chip(
          label: isPreset ? 'Other' : fmt.formatTimeOfDay(selected, alwaysUse24HourFormat: false),
          active: !isPreset,
          onTap: () {
            UiSound.instance.tap();
            onCustom();
          },
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTheme.activityGreen : AppTheme.surfaceElevated.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: active ? Colors.black : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class SpeedRouteCard extends StatelessWidget {
  const SpeedRouteCard({
    super.key,
    required this.fromLabel,
    required this.fromSub,
    required this.toLabel,
    required this.toSub,
    required this.onFromTap,
    required this.onToTap,
    this.toWork = true,
  });

  final String fromLabel;
  final String fromSub;
  final String toLabel;
  final String toSub;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final bool toWork;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.glassBorder.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            _StopRow(
              dotColor: AppTheme.activityGreen,
              label: toWork ? 'From · Home' : 'From · Office',
              title: fromLabel,
              subtitle: fromSub,
              onTap: onFromTap,
            ),
            Divider(height: 1, color: AppTheme.glassBorder.withValues(alpha: 0.2)),
            _StopRow(
              dotColor: AppTheme.ringCyan,
              label: toWork ? 'To · Office' : 'To · Home',
              title: toLabel,
              subtitle: toSub,
              onTap: onToTap,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.dotColor,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final Color dotColor;
  final String label;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          UiSound.instance.tap();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, isLast ? 12 : 14, 12, isLast ? 14 : 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
