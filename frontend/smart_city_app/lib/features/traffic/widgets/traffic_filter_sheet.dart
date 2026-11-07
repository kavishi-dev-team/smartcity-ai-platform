import 'package:flutter/material.dart';

import '../models/traffic_issue_model.dart';
import '../providers/traffic_provider.dart';

class TrafficFilterSheet extends StatefulWidget {
  final TrafficFilters initial;
  const TrafficFilterSheet({super.key, required this.initial});

  @override
  State<TrafficFilterSheet> createState() => _TrafficFilterSheetState();
}

class _TrafficFilterSheetState extends State<TrafficFilterSheet> {
  late String _status;
  late String _priority;
  late TextEditingController _city;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
    _priority = widget.initial.priority;
    _city = TextEditingController(text: widget.initial.city);
    _from = widget.initial.dateFrom;
    _to = widget.initial.dateTo;
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _from = selected;
        if (_to != null && _to!.isBefore(selected)) _to = null;
      } else {
        _to = selected;
        if (_from != null && _from!.isAfter(selected)) _from = null;
      }
    });
  }

  void _submit({bool clear = false}) {
    Navigator.pop(
      context,
      clear
          ? TrafficFilters(search: widget.initial.search)
          : TrafficFilters(
              search: widget.initial.search,
              status: _status,
              priority: _priority,
              city: _city.text.trim(),
              dateFrom: _from,
              dateTo: _to,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Filter Traffic Problems', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: '', child: Text('All priorities')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) => setState(() => _priority = value ?? ''),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('All statuses')),
                DropdownMenuItem(value: 'reported', child: Text('Reported')),
                DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) => setState(() => _status = value ?? ''),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City / Location', prefixIcon: Icon(Icons.location_city)),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _pickDate(start: true),
                icon: const Icon(Icons.event),
                label: Text(_from == null ? 'From date' : trafficDate(_from!)),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _pickDate(start: false),
                icon: const Icon(Icons.event),
                label: Text(_to == null ? 'To date' : trafficDate(_to!)),
              )),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => _submit(clear: true), child: const Text('Clear filters'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => _submit(), child: const Text('Apply filters'))),
            ]),
          ]),
        ),
      ),
    );
  }
}
