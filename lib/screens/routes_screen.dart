import 'package:flutter/material.dart';

import '../models/route_option.dart';
import '../theme/app_theme.dart';
import 'run_screen.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({
    super.key,
    required this.routes,
    required this.paceMinPerKm,
  });

  final List<RouteOption> routes;
  final double paceMinPerKm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${routes.length} options · ranked for you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: routes.length,
        itemBuilder: (context, i) => _RouteCard(
          route: routes[i],
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RunScreen(
                  route: routes[i],
                  paceMinPerKm: paceMinPerKm,
                ),
              ),
            );
          },
        ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isBest ? AppTheme.surfaceElevated : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isBest ? AppTheme.textPrimary : AppTheme.border,
                width: isBest ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route.rank}',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -2,
                        color: AppTheme.textPrimary,
                      ),
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
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isBest ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            route.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          route.score.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'SCORE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _Stat(
                      value: route.distanceKm.toStringAsFixed(1),
                      unit: 'KM',
                    ),
                    _divider(),
                    _Stat(
                      value: route.estimatedDurationMin.round().toString(),
                      unit: 'MIN',
                    ),
                    _divider(),
                    _Stat(
                      value: '${route.turns}',
                      unit: 'TURNS',
                    ),
                    _divider(),
                    _Stat(
                      value: '${route.signalStops}',
                      unit: 'STOPS',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${route.greenWaveScore.toStringAsFixed(0)}% green · '
                  '${route.signalWaitTotalSec}s signal wait',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppTheme.border,
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
