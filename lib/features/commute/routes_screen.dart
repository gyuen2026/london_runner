import 'package:flutter/material.dart';

import 'package:london_runner/core/services/ui_sound.dart';
import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/core/widgets/glass_panel.dart';
import 'package:london_runner/features/commute/models/route_option.dart';
import 'package:london_runner/features/commute/widgets/speed_ui.dart';
import 'package:london_runner/features/commute/widgets/watch_ui.dart';
import 'package:london_runner/features/navigate/route_map_screen.dart';
class RoutesScreen extends StatelessWidget {
  const RoutesScreen({
    super.key,
    required this.routes,
    required this.paceMinPerKm,
    this.title = 'Routes',
    this.subtitle,
  });

  final List<RouteOption> routes;
  final double paceMinPerKm;
  final String title;
  final String? subtitle;

  void _openRoute(BuildContext context, RouteOption route) {
    UiSound.instance.tap();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteMapScreen(
          route: route,
          paceMinPerKm: route.suggestedPaceMinPerKm ?? paceMinPerKm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final best = routes.isNotEmpty ? routes.first : null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          if (best != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SpeedGoButton(
                label: 'Start · ${best.greenWaveScore.toStringAsFixed(0)}% green',
                onPressed: () => _openRoute(context, best),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: routes.length,
              itemBuilder: (context, i) => _RouteCard(
                route: routes[i],
                onTap: () => _openRoute(context, routes[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});

  final RouteOption route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBest = route.rank == 1;
    final green = route.greenWaveScore.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: GlassPanel(
            padding: const EdgeInsets.all(16),
            borderRadius: AppTheme.radiusMd,
            tint: isBest ? AppTheme.runGreen.withValues(alpha: 0.08) : null,
            child: Row(
              children: [
                WatchMetric(
                  label: 'Green',
                  value: green,
                  unit: '%',
                  accent: isBest ? AppTheme.runGreen : AppTheme.standCyan,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (route.badge.isNotEmpty)
                        Text(
                          route.badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isBest ? AppTheme.runGreen : AppTheme.textSecondary,
                          ),
                        ),
                      if (route.badge.isNotEmpty) const SizedBox(height: 4),
                      Text(route.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${route.distanceKm.toStringAsFixed(1)} km · '
                        '${route.estimatedDurationMin.round()} min · '
                        '#${route.rank}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                      ),
                      if (route.isGreenCommute && route.suggestedPaceMinPerKm != null)
                        Text(
                          'Pace ${route.suggestedPaceMinPerKm!.toStringAsFixed(1)} · Leave ${route.departAtLabel ?? "—"}',
                          style: const TextStyle(
                            color: AppTheme.runGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
