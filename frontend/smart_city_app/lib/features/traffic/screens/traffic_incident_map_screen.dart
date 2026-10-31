import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../models/traffic_issue_model.dart';
import '../services/traffic_service.dart';
import 'traffic_problem_details_screen.dart';

class TrafficIncidentMapScreen extends StatefulWidget {
  final TrafficService? service;

  const TrafficIncidentMapScreen({super.key, this.service});

  @override
  State<TrafficIncidentMapScreen> createState() =>
      _TrafficIncidentMapScreenState();
}

class _TrafficIncidentMapScreenState extends State<TrafficIncidentMapScreen> {
  static const _tileUrl = String.fromEnvironment(
    'TRAFFIC_MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  late final TrafficService _service;
  late final bool _ownsService;
  late Future<TrafficMapPage> _future;
  final MapController _mapController = MapController();
  String _status = '';
  TrafficMapMarker? _selected;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? TrafficService();
    _future = _service.getMapMarkers();
  }

  @override
  void dispose() {
    _mapController.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _selected = null;
      _future = _service.getMapMarkers();
    });
  }

  Color _pinColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'reported':
        return AppColors.error;
      case 'in_progress':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  void _fitMarkers(List<TrafficMapMarker> markers) {
    if (markers.isEmpty) return;
    if (markers.length == 1) {
      final loc = markers.first.location;
      _mapController.move(LatLng(loc.latitude, loc.longitude), 14);
      return;
    }
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints([
        for (final item in markers)
          LatLng(item.location.latitude, item.location.longitude),
      ]),
      padding: const EdgeInsets.all(52),
    ));
  }

  void _openDetails(TrafficMapMarker marker) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TrafficProblemDetailsScreen(
        issueId: marker.id,
        service: _service,
      ),
    ));
  }

  Widget _message(IconData icon, String title, String detail) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 52, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh map'),
            ),
          ]),
        ),
      );

  Widget _mapContent(TrafficMapPage page) {
    // Filter in-memory so changing the status does not issue a new API request.
    final markers = page.items.where((marker) =>
        _status.isEmpty || marker.status.toLowerCase() == _status).toList();
    final activeSelected = _selected != null &&
        markers.any((marker) => marker.id == _selected!.id)
        ? _selected
        : null;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Traffic Incident Map',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 5),
          Text('${markers.length} mapped reports  •  ${page.total} locations available',
              style: const TextStyle(color: AppColors.muted)),
          if (page.total > page.items.length)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Showing the latest 500 reports. Use the Traffic List to see more.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final entry in const [
                ('', 'All'),
                ('reported', 'Reported'),
                ('in_progress', 'In progress'),
                ('resolved', 'Resolved'),
              ]) ...[
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: _status == entry.$1,
                  onSelected: (_) => setState(() {
                    _status = entry.$1;
                    _selected = null;
                  }),
                ),
                const SizedBox(width: 8),
              ],
            ]),
          ),
        ]),
      ),
      Expanded(
        child: markers.isEmpty
            ? _message(Icons.location_off_outlined,
                'No traffic incidents to map',
                'Reports without coordinates are not shown. Try All or refresh.')
            : Stack(children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    // Sri Lanka fallback, used only for the initial camera.
                    initialCenter: const LatLng(7.8731, 80.7718),
                    initialZoom: 7.5,
                    initialCameraFit: markers.length > 1
                        ? CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints([
                              for (final item in markers)
                                LatLng(item.location.latitude,
                                    item.location.longitude),
                            ]),
                            padding: const EdgeInsets.all(52),
                          )
                        : null,
                    onTap: (_, __) => setState(() => _selected = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _tileUrl,
                      userAgentPackageName: 'lk.smartcity.ai_platform',
                    ),
                    MarkerLayer(markers: [
                      for (final item in markers)
                        Marker(
                          point: LatLng(item.location.latitude,
                              item.location.longitude),
                          width: 48,
                          height: 48,
                          child: GestureDetector(
                            key: Key('traffic-map-marker-${item.id}'),
                            onTap: () => setState(() => _selected = item),
                            child: Tooltip(
                              message: item.title,
                              child: Icon(Icons.location_on,
                                  color: _pinColor(item.status),
                                  size: activeSelected?.id == item.id ? 48 : 42,
                                  shadows: const [Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  )]),
                            ),
                          ),
                        ),
                    ]),
                    const SimpleAttributionWidget(
                      source: Text('© OpenStreetMap contributors'),
                    ),
                  ],
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      tooltip: 'Fit all markers',
                      icon: const Icon(Icons.center_focus_strong,
                          color: AppColors.primary),
                      onPressed: () => _fitMarkers(markers),
                    ),
                  ),
                ),
              ]),
      ),
      if (activeSelected != null)
        Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(activeSelected.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      color: AppColors.text))),
                IconButton(
                  tooltip: 'Close marker details',
                  onPressed: () => setState(() => _selected = null),
                  icon: const Icon(Icons.close, size: 19),
                ),
              ]),
              Text('${trafficLabel(activeSelected.status)}  •  '
                  '${trafficLabel(activeSelected.priority)} priority',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(activeSelected.location.address ??
                  activeSelected.location.city ?? 'Location available on map',
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openDetails(activeSelected),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View report details'),
                ),
              ),
            ]),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Traffic Incident Map'), actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Refresh markers from MySQL',
            icon: const Icon(Icons.refresh),
          ),
        ]),
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: FutureBuilder<TrafficMapPage>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _message(Icons.wifi_off_outlined,
                        'Unable to load the incident map',
                        '${snapshot.error}');
                  }
                  return _mapContent(snapshot.data!);
                },
              ),
            ),
          ),
        ),
      );
}
