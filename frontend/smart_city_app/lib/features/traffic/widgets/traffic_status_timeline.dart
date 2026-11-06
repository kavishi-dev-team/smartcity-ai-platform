import 'package:flutter/material.dart';

import '../models/traffic_issue_model.dart';

class TrafficStatusTimeline extends StatelessWidget {
  final List<TrafficHistoryItem> history;
  const TrafficStatusTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const Text('No status updates yet.');
    return Column(
      children: [
        for (final entry in history)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(trafficLabel(entry.newStatus)),
            subtitle: Text([
              trafficDate(entry.createdAt),
              if (entry.note?.trim().isNotEmpty == true) entry.note!,
            ].join(' • ')),
          ),
      ],
    );
  }
}
