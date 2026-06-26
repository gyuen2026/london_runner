import 'package:flutter/material.dart';

import 'package:london_runner/core/services/health_service.dart';
import 'package:london_runner/core/services/voice_coach.dart';
import 'package:london_runner/core/services/voice_settings.dart';
import 'package:london_runner/core/theme/app_theme.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.voice});

  final VoiceCoach voice;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _health = HealthService();
  double? _pace;
  int _hr = 0;
  bool _loading = true;
  VoiceMode _voiceMode = VoiceMode.female;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pace = await _health.averageRunPaceMinPerKm();
    final hr = await _health.latestHeartRate();
    if (!mounted) return;
    setState(() {
      _pace = pace;
      _hr = hr;
      _voiceMode = widget.voice.settings.mode;
      _loading = false;
    });
  }

  Future<void> _setVoice(VoiceMode mode) async {
    await widget.voice.setMode(mode);
    setState(() => _voiceMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('Connected data sources', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            _Section(
              title: 'APPLE HEALTH',
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Column(
                      children: [
                        _StatusRow(
                          label: 'Median run pace',
                          value: _pace != null ? '${_pace!.toStringAsFixed(1)} min/km' : 'Not linked',
                          linked: _pace != null,
                        ),
                        const SizedBox(height: 12),
                        _StatusRow(
                          label: 'Latest heart rate',
                          value: _hr > 0 ? '$_hr bpm' : 'No recent reading',
                          linked: _hr > 0,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'APPLE WATCH',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusRow(
                    label: 'Workout sync',
                    value: 'Via HealthKit (same Apple ID)',
                    linked: _pace != null || _hr > 0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Watch runs appear in Health → used automatically for pace on Home.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'VOICE COACH',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default line when clear: “Your route is clear. Continue on your current path.”',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<VoiceMode>(
                    segments: const [
                      ButtonSegment(value: VoiceMode.off, label: Text('Off')),
                      ButtonSegment(value: VoiceMode.female, label: Text('Female')),
                      ButtonSegment(value: VoiceMode.male, label: Text('Male')),
                    ],
                    selected: {_voiceMode},
                    onSelectionChanged: (s) => _setVoice(s.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Refresh health data')),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.linked,
  });

  final String label;
  final String value;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          linked ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: linked ? AppTheme.accentRun : AppTheme.textTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
