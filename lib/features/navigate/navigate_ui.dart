import 'package:flutter/material.dart';

import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/core/widgets/glass_panel.dart';
import 'package:london_runner/features/search/models/place_location.dart';
import 'route_navigation.dart';
class MapCircleButton extends StatelessWidget {
  const MapCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

/// Google Maps–style search bar row (back + field).
class MapSearchTopBar extends StatelessWidget {
  const MapSearchTopBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            MapCircleButton(
              icon: Icons.arrow_back,
              onTap: onBack ?? () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                borderRadius: 14,
                blur: 14,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: onClear,
                              )
                            : null),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet shell — shared rounded top panel for map overlays.
class MapBottomSheet extends StatelessWidget {
  const MapBottomSheet({
    super.key,
    required this.child,
    this.showHandle = true,
  });

  final Widget child;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.border.withValues(alpha: 0.8))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle) ...[
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Place picker sheets ─────────────────────────────────────────────────────

class PlaceSearchResultsSheet extends StatelessWidget {
  const PlaceSearchResultsSheet({
    super.key,
    required this.title,
    required this.suggestions,
    required this.selected,
    required this.pinColor,
    required this.scrollController,
    required this.onSelect,
  });

  final String title;
  final List<PlaceLocation> suggestions;
  final PlaceLocation? selected;
  final Color pinColor;
  final ScrollController scrollController;
  final ValueChanged<PlaceLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    return MapBottomSheet(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                Text(
                  '${suggestions.length} results · tap to pick',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (context, i) {
                final p = suggestions[i];
                final isSelected = selected != null &&
                    (p.lat - selected!.lat).abs() < 0.00001 &&
                    (p.lon - selected!.lon).abs() < 0.00001;
                return Material(
                  color: isSelected ? pinColor.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelect(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.storefront_outlined,
                              color: isSelected ? pinColor : AppTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.titleLine,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                    color: isSelected ? pinColor : AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.addressLine,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (p.distanceLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              p.distanceLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceConfirmSheet extends StatelessWidget {
  const PlaceConfirmSheet({
    super.key,
    required this.place,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final PlaceLocation place;
  final String confirmLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: MapBottomSheet(
        showHandle: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.titleLine, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                place.addressLine,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Route preview (before run) ──────────────────────────────────────────────

class RoutePreviewSheet extends StatelessWidget {
  const RoutePreviewSheet({
    super.key,
    required this.distanceKm,
    required this.durationMin,
    required this.greenPct,
    required this.onStart,
  });

  final double distanceKm;
  final double durationMin;
  final double greenPct;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: MapBottomSheet(
        showHandle: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${distanceKm.toStringAsFixed(1)} km · '
                '${durationMin.round()} min · '
                '${greenPct.toStringAsFixed(0)}% green',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 14),
              FilledButton(onPressed: onStart, child: const Text('Start Run')),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live navigation layout ──────────────────────────────────────────────────

/// Traffic-signal pill shown during a run.
class NavigateSignalPill extends StatelessWidget {
  const NavigateSignalPill({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Green-wave progress chip during run.
class NavigateProgressChip extends StatelessWidget {
  const NavigateProgressChip({
    super.key,
    required this.greenPct,
    required this.remainingKm,
  });

  final double greenPct;
  final double remainingKm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: greenPct / 100,
              strokeWidth: 3,
              backgroundColor: AppTheme.surfaceElevated,
              color: AppTheme.runGreen,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${greenPct.round()}% · ${remainingKm.toStringAsFixed(1)} km left',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Google Maps–style full-width direction header at top of map.
class NavigateDirectionHeader extends StatelessWidget {
  const NavigateDirectionHeader({
    super.key,
    required this.primary,
    required this.secondary,
    required this.distanceM,
    required this.instruction,
    this.offRoute = false,
  });

  final String primary;
  final String secondary;
  final double distanceM;
  final String instruction;
  final bool offRoute;

  IconData get _arrow {
    final lower = instruction.toLowerCase();
    if (lower.contains('left') && lower.contains('around')) return Icons.u_turn_left;
    if (lower.contains('left')) return Icons.turn_left;
    if (lower.contains('right')) return Icons.turn_right;
    if (lower.contains('arrived')) return Icons.flag;
    return Icons.arrow_upward;
  }

  String get _distanceLabel {
    if (distanceM < 35) return 'Now';
    if (distanceM < 1000) return '${distanceM.round()} m';
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final accent = offRoute ? AppTheme.signalRed : AppTheme.runGreen;
    return Container(
      width: double.infinity,
      color: AppTheme.surface.withValues(alpha: 0.96),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Icon(_arrow, color: accent, size: 36),
                const SizedBox(height: 2),
                Text(
                  _distanceLabel,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  secondary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom metrics bar — Apple Fitness Outdoor Run style.
class NavigateMetricsBar extends StatelessWidget {
  const NavigateMetricsBar({
    super.key,
    required this.time,
    required this.distanceKm,
    required this.pace,
    required this.heartRate,
  });

  final String time;
  final String distanceKm;
  final String pace;
  final String heartRate;

  @override
  Widget build(BuildContext context) {
    return MapBottomSheet(
      showHandle: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Row(
          children: [
            _Metric(value: time, label: 'TIME'),
            _Metric(value: distanceKm, label: 'DISTANCE'),
            _Metric(value: pace, label: 'PACE'),
            _Metric(value: heartRate, label: 'BPM', accent: AppTheme.movePink),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.accent});

  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: accent ?? AppTheme.textPrimary,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Full-screen map overlay shell for live navigation.
class NavigateRunLayout extends StatelessWidget {
  const NavigateRunLayout({
    super.key,
    required this.onClose,
    required this.signalColor,
    required this.signalLabel,
    this.greenPct,
    this.remainingKm,
    required this.offRoute,
    required this.progressData,
    this.coachText,
    required this.time,
    required this.distanceKm,
    required this.pace,
    required this.heartRate,
    this.errorText,
    this.runComplete = false,
    this.onRunCompleteDismiss,
    this.greenWaveScore,
  });

  final VoidCallback onClose;
  final Color signalColor;
  final String signalLabel;
  final RouteProgress? progressData;
  final bool offRoute;
  final double? greenPct;
  final double? remainingKm;
  final String? coachText;
  final String time;
  final String distanceKm;
  final String pace;
  final String heartRate;
  final String? errorText;
  final bool runComplete;
  final VoidCallback? onRunCompleteDismiss;
  final double? greenWaveScore;

  @override
  Widget build(BuildContext context) {
    final prog = progressData;

    return Stack(
      children: [
        // Top chrome: close + pills, then direction header
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    MapCircleButton(icon: Icons.close, onTap: onClose),
                    const Spacer(),
                    NavigateSignalPill(color: signalColor, label: signalLabel),
                    if (greenPct != null && remainingKm != null) ...[
                      const SizedBox(width: 8),
                      NavigateProgressChip(greenPct: greenPct!, remainingKm: remainingKm!),
                    ],
                  ],
                ),
              ),
            ),
            if (prog != null)
              NavigateDirectionHeader(
                primary: offRoute ? 'Return to route' : prog.primaryInstruction,
                secondary: offRoute
                    ? '${prog.offRouteM.round()} m off path'
                    : prog.secondaryInstruction,
                distanceM: offRoute ? prog.offRouteM : prog.distanceToNextTurnM,
                instruction: prog.primaryInstruction,
                offRoute: offRoute,
              ),
          ],
        ),

        if (runComplete)
          RunCompleteOverlay(
            greenWaveScore: greenWaveScore ?? 0,
            onDismiss: onRunCompleteDismiss ?? () => Navigator.of(context).pop(),
          ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (coachText != null && coachText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    child: Text(coachText!, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              NavigateMetricsBar(
                time: time,
                distanceKm: distanceKm,
                pace: pace,
                heartRate: heartRate,
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(errorText!, style: const TextStyle(color: AppTheme.signalRed, fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class RunCompleteOverlay extends StatelessWidget {
  const RunCompleteOverlay({
    super.key,
    required this.greenWaveScore,
    required this.onDismiss,
  });

  final double greenWaveScore;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: GlassPanel(
          padding: const EdgeInsets.all(28),
          borderRadius: AppTheme.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.runGreen, size: 56),
              const SizedBox(height: 16),
              Text('Run Complete', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${greenWaveScore.toStringAsFixed(0)}% green wave',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onDismiss, child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
  }
}
