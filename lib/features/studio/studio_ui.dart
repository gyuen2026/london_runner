import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/features/commute/models/crosswalk_point.dart';
import 'package:london_runner/features/commute/models/route_option.dart';
import 'package:london_runner/features/maps/adaptive_map_controller.dart';
import 'package:london_runner/features/maps/adaptive_map_view.dart';
import 'package:london_runner/features/navigate/crosswalk_markers.dart';
import 'package:london_runner/features/navigate/map_layers.dart';
import 'package:london_runner/features/studio/mobile_qr_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Studio AI design system — neon green tactical dashboard.
class StudioTheme {
  static const neon = Color(0xFF39FF14);
  static const neonDim = Color(0xFF2BD912);
  static const card = Color(0xFF141414);
  static const cardBorder = Color(0xFF2A2A2A);
  static const paceYellow = Color(0xFFFFD60A);
  static const distanceBlue = Color(0xFF64D2FF);
  static const heartRed = Color(0xFFFF453A);
  static const radius = 18.0;
}

// ─── Header ───────────────────────────────────────────────────────────────────

class StudioHeader extends StatelessWidget {
  const StudioHeader({
    super.key,
    this.onHud,
    this.onQr,
    this.onBack,
    this.showBack = false,
  });

  final VoidCallback? onHud;
  final VoidCallback? onQr;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(
        children: [
          const Text(
            'GEENGREEN',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          _HeaderIcon(icon: Icons.visibility_outlined, onTap: onHud),
          const SizedBox(width: 8),
          _HeaderIcon(
            icon: Icons.qr_code_2,
            onTap: onQr ?? () => showStudioQrDialog(context),
          ),
          const SizedBox(width: 8),
          if (showBack)
            _HeaderIcon(icon: Icons.arrow_back, onTap: onBack ?? () => Navigator.maybePop(context)),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StudioTheme.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

// ─── Cards & inputs ─────────────────────────────────────────────────────────

class StudioCard extends StatelessWidget {
  const StudioCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: StudioTheme.card,
        borderRadius: BorderRadius.circular(StudioTheme.radius),
        border: Border.all(color: StudioTheme.cardBorder),
      ),
      child: child,
    );
  }
}

class StudioRouteInputCard extends StatelessWidget {
  const StudioRouteInputCard({
    super.key,
    required this.fromLabel,
    required this.toLabel,
    required this.onFromTap,
    required this.onToTap,
    this.onSparkle,
    this.subtitle = 'Define origin and destination inside London Zone 1-2.',
  });

  final String fromLabel;
  final String toLabel;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback? onSparkle;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return StudioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Where's your green-wave run?",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              if (onSparkle != null)
                IconButton(
                  onPressed: onSparkle,
                  icon: const Icon(Icons.auto_awesome, color: StudioTheme.neon, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SearchRow(
            label: 'FROM (ORIGIN)',
            pinColor: StudioTheme.neon,
            value: fromLabel,
            hint: 'Search place, e.g. Rotherhithe, SE16',
            onTap: onFromTap,
          ),
          const SizedBox(height: 12),
          _SearchRow(
            label: 'TO (DESTINATION)',
            pinColor: AppTheme.signalRed,
            value: toLabel,
            hint: 'Search place, e.g. Victoria Station',
            onTap: onToTap,
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.label,
    required this.pinColor,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final Color pinColor;
  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty || value.startsWith('Search') || value == 'Set start' || value == 'Set end';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: pinColor),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: pinColor, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: AppTheme.textTertiary.withValues(alpha: 0.8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      empty ? hint : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                        color: empty ? AppTheme.textTertiary : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StudioPreviewMap extends StatelessWidget {
  const StudioPreviewMap({
    super.key,
    required this.controller,
    this.points = const [],
    this.center,
    this.crossings = const [],
    this.activeCrossingIndex,
    this.crossingColors = const {},
  });

  final AdaptiveMapController controller;
  final List<LatLng> points;
  final LatLng? center;
  final List<CrosswalkPoint> crossings;
  final int? activeCrossingIndex;
  final Map<int, String> crossingColors;

  @override
  Widget build(BuildContext context) {
    final googlePolylines = points.length >= 2
        ? {
            gmaps.Polyline(
              polylineId: const gmaps.PolylineId('route'),
              points: toGooglePath(points),
              color: StudioTheme.neon,
              width: 5,
            ),
          }
        : <gmaps.Polyline>{};

    final googleMarkers = <gmaps.Marker>{};
    if (points.isNotEmpty) {
      googleMarkers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('start'),
        position: toGoogleLatLng(points.first),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
      ));
      if (points.length > 1) {
        googleMarkers.add(gmaps.Marker(
          markerId: const gmaps.MarkerId('end'),
          position: toGoogleLatLng(points.last),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
        ));
      }
    }
    googleMarkers.addAll(googleCrosswalkMarkers(
      crossings,
      activeIndex: activeCrossingIndex,
      signalColors: crossingColors,
    ));

    final xingMarkers = flutterCrosswalkMarkers(
      crossings,
      activeIndex: activeCrossingIndex,
      signalColors: crossingColors,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(StudioTheme.radius),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            AdaptiveMapView(
              controller: controller,
              initialCenter: center ?? const LatLng(51.5074, -0.1278),
              initialZoom: points.length >= 2 ? 13 : 12,
              polylines: points.length >= 2
                  ? [routePolyline(points, color: StudioTheme.neon, width: 5)]
                  : const [],
              flutterMarkers: [
                if (points.isNotEmpty)
                  Marker(
                    point: points.first,
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: const BoxDecoration(color: StudioTheme.neon, shape: BoxShape.circle),
                    ),
                  ),
                if (points.length > 1)
                  Marker(
                    point: points.last,
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: const BoxDecoration(color: AppTheme.signalRed, shape: BoxShape.circle),
                    ),
                  ),
                ...xingMarkers,
              ],
              googlePolylines: googlePolylines,
              googleMarkers: googleMarkers,
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: AdaptiveMapZoomControls(controller: controller),
            ),
            const Positioned(
              right: 10,
              top: 10,
              child: _TflBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TflBadge extends StatelessWidget {
  const _TflBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudioTheme.cardBorder),
      ),
      child: const Text(
        'TFL CORRIDOR ACTIVE',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}

// ─── Routes list ──────────────────────────────────────────────────────────────

class StudioPathwayHeader extends StatelessWidget {
  const StudioPathwayHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$count PATHWAYS COMPUTED',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
          const Spacer(),
          const Text(
            'GREEN WAVE PRIORITIZED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: StudioTheme.neon,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class StudioPathwayCard extends StatelessWidget {
  const StudioPathwayCard({
    super.key,
    required this.route,
    required this.selected,
    required this.onTap,
  });

  final RouteOption route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGreen = route.rank == 1;
    final title = isGreen ? 'Green Wave Direct' : (route.badge.isNotEmpty ? route.badge : route.name);
    final desc = isGreen
        ? 'Optimized to synchronize with traffic cycles and avoid bus corridors.'
        : (route.description.isNotEmpty
            ? route.description
            : 'Alternative path with different signal timing.');
    final linked = route.pedSignalsOnPath > 0
        ? (route.signalStops.clamp(0, route.pedSignalsOnPath))
        : route.signalStops;
    final total = route.pedSignalsOnPath > 0 ? route.pedSignalsOnPath : 28;
    final busCongestion = (route.turns.clamp(0, 10));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StudioTheme.radius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StudioTheme.card,
              borderRadius: BorderRadius.circular(StudioTheme.radius),
              border: Border.all(
                color: selected ? StudioTheme.neon : StudioTheme.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isGreen ? Icons.auto_awesome : Icons.bolt,
                      color: isGreen ? StudioTheme.neon : StudioTheme.distanceBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(desc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${route.estimatedDurationMin.round()} min',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          '${route.distanceKm.toStringAsFixed(2)} km',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isGreen) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Green Wave Score',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                      const Spacer(),
                      Text(
                        '${route.greenWaveScore.round()}%',
                        style: const TextStyle(
                          color: StudioTheme.neon,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: route.greenWaveScore / 100,
                      minHeight: 6,
                      backgroundColor: AppTheme.surfaceElevated,
                      color: StudioTheme.neon,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatBadge(
                        label: '연동/총 신호',
                        value: '$linked / ${total}개',
                        accent: StudioTheme.neon,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        label: '버스 혼잡',
                        value: '$busCongestion/10',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: StudioTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: accent ?? AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudioGoButton extends StatelessWidget {
  const StudioGoButton({super.key, required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: StudioTheme.neon,
          foregroundColor: Colors.black,
          disabledBackgroundColor: StudioTheme.neon.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : const Icon(Icons.play_arrow_rounded, size: 26),
        label: Text(
          loading ? 'COMPUTING…' : 'GO — START COMMUTE RUN',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
        ),
      ),
    );
  }
}

// ─── Workout dashboard ────────────────────────────────────────────────────────

class StudioWorkoutDashboard extends StatelessWidget {
  const StudioWorkoutDashboard({
    super.key,
    required this.navPrimary,
    required this.navSecondary,
    required this.time,
    required this.distanceKm,
    required this.pace,
    required this.heartRate,
    required this.signalsPassed,
    required this.signalsTotal,
    required this.greenLinked,
    required this.greenWavePct,
    required this.signalCountdown,
    required this.onPause,
    required this.onEnd,
  });

  final String navPrimary;
  final String navSecondary;
  final String time;
  final String distanceKm;
  final String pace;
  final String heartRate;
  final int signalsPassed;
  final int signalsTotal;
  final int greenLinked;
  final double greenWavePct;
  final String signalCountdown;
  final VoidCallback onPause;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const StudioHeader(showBack: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: StudioTheme.neon, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('WORKOUT ACTIVE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const Spacer(),
                Text(
                  'OUTDOOR RUN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  StudioCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NavBanner(primary: navPrimary, secondary: navSecondary),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _HeroMetric(label: 'TIME\n(경과 시간)', value: time, color: StudioTheme.neon)),
                            Expanded(
                              child: _HeroMetric(
                                label: 'DISTANCE\n(남은 거리)',
                                value: distanceKm,
                                unit: 'KM',
                                color: StudioTheme.distanceBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _HeroMetric(
                                label: 'PACE\n(페이스)',
                                value: pace,
                                unit: '/KM',
                                color: StudioTheme.paceYellow,
                              ),
                            ),
                            Expanded(
                              child: _HeroMetric(
                                label: 'HEART\n(심박수)',
                                value: heartRate,
                                unit: 'BPM',
                                color: StudioTheme.heartRed,
                                icon: Icons.favorite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'SIGNALS PASSED (지나온 신호등/횡단보도)',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$signalsPassed / ${signalsTotal}개',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(그린웨이브 연동: ${greenLinked}개)',
                              style: const TextStyle(color: StudioTheme.neon, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: StudioTheme.neon, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  signalCountdown,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: StudioTheme.neon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onPause,
                                icon: const Icon(Icons.pause, size: 18),
                                label: const Text('Pause (일시 정지)'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary,
                                  side: const BorderSide(color: StudioTheme.cardBorder),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onEnd,
                                icon: const Icon(Icons.stop, size: 18),
                                label: const Text('End (종료)'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.signalRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: StudioMiniMetric(icon: Icons.schedule, label: 'TIME', value: time, sub: 'ELAPSED TIMER')),
                      const SizedBox(width: 8),
                      Expanded(child: StudioMiniMetric(icon: Icons.navigation, label: 'DISTANCE', value: distanceKm, sub: 'COMMUTE RANGE')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: StudioMiniMetric(icon: Icons.show_chart, label: 'PACE', value: pace, sub: 'DYNAMIC SPEED')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StudioMiniMetric(
                          icon: Icons.favorite_border,
                          label: 'HEART RATE',
                          value: heartRate,
                          sub: 'CARDIO FEED',
                          accent: StudioTheme.heartRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StudioMiniMetric(
                          icon: Icons.traffic,
                          label: 'CROSSWALKS',
                          value: '$signalsPassed / $greenLinked',
                          sub: 'GREEN WAVE: ${greenWavePct.round()}%',
                          accent: StudioTheme.neon,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBanner extends StatelessWidget {
  const _NavBanner({required this.primary, required this.secondary});

  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: StudioTheme.neon.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_upward, color: StudioTheme.neon, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(primary, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(secondary, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    this.unit,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final String? unit;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, height: 1.3)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, letterSpacing: -1),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Text(unit!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: color),
            ],
          ],
        ),
      ],
    );
  }
}

class StudioMiniMetric extends StatelessWidget {
  const StudioMiniMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: StudioTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudioTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
              Icon(icon, size: 14, color: accent ?? AppTheme.textTertiary),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: accent ?? AppTheme.textPrimary,
            ),
          ),
          Text(sub, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 7)),
        ],
      ),
    );
  }
}

// ─── 3D AR cockpit overlay ────────────────────────────────────────────────────

class StudioArCockpitOverlay extends StatelessWidget {
  const StudioArCockpitOverlay({
    super.key,
    required this.arMode,
    required this.onToggleAr,
    required this.paceLabel,
    required this.targetPace,
    required this.signalPhaseLabel,
    required this.signalCountdownLabel,
    required this.signalCountdownSec,
    required this.busDelaySec,
    required this.jamcamDensity,
    required this.offsetSec,
    required this.navPrimary,
    required this.timeLabel,
    required this.distanceLabel,
    required this.heartRateLabel,
    required this.signalsPassed,
    required this.signalsTotal,
    required this.greenWavePct,
    this.upcomingCrossings = const [],
    this.crossingCountdownLabels = const {},
    this.crossingCountdownSecs = const {},
  });

  final bool arMode;
  final ValueChanged<bool> onToggleAr;
  final String paceLabel;
  final String targetPace;
  final String signalPhaseLabel;
  final String signalCountdownLabel;
  final int signalCountdownSec;
  final int busDelaySec;
  final String jamcamDensity;
  final int offsetSec;
  final String navPrimary;
  final String timeLabel;
  final String distanceLabel;
  final String heartRateLabel;
  final int signalsPassed;
  final int signalsTotal;
  final int greenWavePct;
  final List<CrosswalkPoint> upcomingCrossings;
  final Map<int, String> crossingCountdownLabels;
  final Map<int, int> crossingCountdownSecs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 12,
          right: 12,
          top: 8,
          child: Row(
            children: [
              Expanded(child: StudioMiniMetric(icon: Icons.schedule, label: 'TIME', value: timeLabel, sub: 'ELAPSED')),
              const SizedBox(width: 6),
              Expanded(child: StudioMiniMetric(icon: Icons.navigation, label: 'DIST', value: distanceLabel, sub: 'KM')),
              const SizedBox(width: 6),
              Expanded(child: StudioMiniMetric(icon: Icons.show_chart, label: 'PACE', value: paceLabel, sub: 'DYNAMIC')),
              const SizedBox(width: 6),
              Expanded(child: StudioMiniMetric(icon: Icons.favorite_border, label: 'HR', value: heartRateLabel, sub: 'BPM')),
              const SizedBox(width: 6),
              Expanded(
                child: StudioMiniMetric(
                  icon: Icons.traffic,
                  label: 'XING',
                  value: '$signalsPassed/$signalsTotal',
                  sub: 'GW $greenWavePct%',
                  accent: StudioTheme.neon,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: 88,
          child: _NavChip(text: navPrimary),
        ),
        Positioned(
          right: 12,
          top: 88,
          child: _ModeToggle(arMode: arMode, onChanged: onToggleAr),
        ),
        Positioned(
          right: 12,
          top: 132,
          child: _SignalBox(
            phaseLabel: signalPhaseLabel,
            countdownLabel: signalCountdownLabel,
            countdownSec: signalCountdownSec,
          ),
        ),
        if (upcomingCrossings.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            top: 132,
            child: _ArCrossingStrip(
              crossings: upcomingCrossings,
              countdownLabels: crossingCountdownLabels,
              countdownSecs: crossingCountdownSecs,
            ),
          ),
        Positioned(
          left: 12,
          bottom: 100,
          child: _PaceVelocityCard(pace: paceLabel, target: targetPace),
        ),
        Positioned(
          right: 12,
          bottom: 100,
          child: _SupabaseMatchCard(
            busDelay: busDelaySec,
            density: jamcamDensity,
            offset: offsetSec,
          ),
        ),
        if (arMode)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _PerspectiveRoadPainter()),
            ),
          ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 56,
          child: Center(
            child: _HudBadge(),
          ),
        ),
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: StudioTheme.neon.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_upward, color: StudioTheme.neon, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.arMode, required this.onChanged});

  final bool arMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudioTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: '3D AR 네비',
            active: arMode,
            onTap: () => onChanged(true),
          ),
          _ToggleChip(
            label: '2D 위성',
            active: !arMode,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? StudioTheme.neon : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: active ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SignalBox extends StatelessWidget {
  const _SignalBox({
    required this.phaseLabel,
    required this.countdownLabel,
    required this.countdownSec,
  });

  final String phaseLabel;
  final String countdownLabel;
  final int countdownSec;

  @override
  Widget build(BuildContext context) {
    final isRed = phaseLabel.contains('빨');
    final isGreen = phaseLabel.contains('초록');
    final accent = isRed
        ? AppTheme.signalRed
        : (isGreen ? StudioTheme.neon : Colors.orange);
    return Container(
      width: 148,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CROSSING SIGNAL', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
          const SizedBox(height: 4),
          Text(
            phaseLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            countdownLabel,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$countdownSec',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: accent,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '초',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArCrossingStrip extends StatelessWidget {
  const _ArCrossingStrip({
    required this.crossings,
    required this.countdownLabels,
    required this.countdownSecs,
  });

  final List<CrosswalkPoint> crossings;
  final Map<int, String> countdownLabels;
  final Map<int, int> countdownSecs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in crossings)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 130,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: StudioTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('XING ${c.index}', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
                    const SizedBox(height: 4),
                    Text(
                      countdownLabels[c.index] ?? '신호 확인 중…',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      maxLines: 1,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${countdownSecs[c.index] ?? '—'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: StudioTheme.neon,
                            height: 1,
                          ),
                        ),
                        if (countdownSecs.containsKey(c.index))
                          const Text(
                            '초',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: StudioTheme.neon),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaceVelocityCard extends StatelessWidget {
  const _PaceVelocityCard({required this.pace, required this.target});

  final String pace;
  final String target;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudioTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PACE VELOCITY', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
          Text(pace, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: StudioTheme.neon)),
          const SizedBox(height: 6),
          Text('TARGET $target matches', style: const TextStyle(fontSize: 9, color: StudioTheme.neon)),
        ],
      ),
    );
  }
}

class _SupabaseMatchCard extends StatelessWidget {
  const _SupabaseMatchCard({
    required this.busDelay,
    required this.density,
    required this.offset,
  });

  final int busDelay;
  final String density;
  final int offset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudioTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUPABASE MATCH', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
          const SizedBox(height: 6),
          _MatchRow('TfL 버스 지연', '+${busDelay}초 보정'),
          _MatchRow('JamCam 밀도', density),
          _MatchRow('신호 오프셋', '+${offset}초'),
          const SizedBox(height: 4),
          const Text(
            'Supabase 실시간 보정 반영',
            style: TextStyle(fontSize: 8, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow(this.k, this.v);

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary))),
          Text(v, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: StudioTheme.neon)),
        ],
      ),
    );
  }
}

class _HudBadge extends StatelessWidget {
  const _HudBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudioTheme.neon.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'HUD LENS ACTIVE',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: StudioTheme.neon, letterSpacing: 0.5),
      ),
    );
  }
}

class _PerspectiveRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = size.height * 0.35;
    final bottom = size.height;

    final path = ui.Path()
      ..moveTo(cx - 40, top)
      ..lineTo(cx - 120, bottom)
      ..lineTo(cx + 120, bottom)
      ..lineTo(cx + 40, top)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = AppTheme.signalRed.withValues(alpha: 0.35),
    );

    for (var i = 0; i < 6; i++) {
      final t = i / 6;
      final y = top + (bottom - top) * (0.2 + t * 0.75);
      final halfW = 40 + (120 - 40) * (y - top) / (bottom - top);
      final dash = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2;
      canvas.drawLine(Offset(cx - halfW * 0.3, y), Offset(cx + halfW * 0.3, y), dash);
    }

    final arrow = ui.Path()
      ..moveTo(cx, top - 20)
      ..lineTo(cx - 14, top + 4)
      ..lineTo(cx + 14, top + 4)
      ..close();
    canvas.drawPath(arrow, Paint()..color = StudioTheme.neon);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void showStudioQrDialog(BuildContext context) {
  showMobileQrDialog(context);
}
