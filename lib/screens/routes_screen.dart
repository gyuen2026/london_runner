import 'package:flutter/material.dart';

import '../models/route_option.dart';
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
      appBar: AppBar(title: const Text('추천 경로')),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, i) {
          final r = routes[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${r.name} · score ${r.score.toStringAsFixed(0)}'),
              subtitle: Text(
                '${r.distanceKm.toStringAsFixed(1)} km · '
                '${r.estimatedDurationMin.toStringAsFixed(0)} min\n'
                '${r.description}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.directions_run),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RunScreen(
                      route: r,
                      paceMinPerKm: paceMinPerKm,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
