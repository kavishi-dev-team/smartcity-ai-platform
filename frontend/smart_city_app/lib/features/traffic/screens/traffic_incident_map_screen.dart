
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../models/traffic_issue_model.dart';
import '../services/traffic_service.dart';
import 'traffic_problem_details_screen.dart';
import 'traffic_problems_screen.dart';

/// Read-only traffic map backed by issue_locations in the existing database.
/// [focusMarker] comes from a real issue, and lets Details -> View on Map
/// work even when that report is outside the latest 500 map results.
class TrafficIncidentMapScreen extends StatefulWidget {
  final TrafficService? service;
  final TrafficMapMarker? focusMarker;
  final bool openedFromList;

  const TrafficIncidentMapScreen({
    super.key,
    this.service,
    this.focusMarker,
    this.openedFromList = false,
  });

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
  final TextEditingController _locationSearch = TextEditingController();

  String _search = '';
  String _status = '';
  TrafficMapMarker? _selected;

  static const _statuses = <(String, String)>[
    ('', 'All'),
    ('reported', 'Reported'),
    ('under_review', 'Under review'),
    ('assigned', 'Assigned'),
    ('in_progress', 'In progress'),
    ('resolved', 'Resolved'),
    ('rejected', 'Rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? TrafficService();
    _selected = widget.focusMarker;
    _future = _service.getMapMarkers();
  }

  @override
  void dispose() {
    _locationSearch.dispose();
    _mapController.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  void _load({bool keepSelection = false}) {
    setState(() {
      if (!keepSelection) _selected = null;
      _future = _service.getMapMarkers(search: _search);
    });
  }

  void _applySearch() {
    final term = _locationSearch.text.trim();
    FocusScope.of(context).unfocus();

    if (term == _search) return;

    setState(() {
      _search = term;
      _status = '';
      _selected = null;
      _future = _service.getMapMarkers(search: term);
    });
  }

  void _clearSearch() {
    _locationSearch.clear();
    _applySearch();
  }

  void _switchToList() {
    if (widget.openedFromList) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TrafficProblemsScreen(service: _service),
        ),
      );
    }
  }

  Color _pinColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'reported':
      case 'rejected':
        return AppColors.error;

      case 'in_progress':
      case 'under_review':
      case 'assigned':
        return AppColors.warning;

      case 'resolved':
        return AppColors.success;

      default:
        return AppColors.primary;
    }
  }

  List<TrafficMapMarker> _matchingMarkers(TrafficMapPage page) {
    final source = [...page.items];
    final focused = widget.focusMarker;

    // Only append a valid real location. Never fabricate a marker.
    if (focused != null &&
        _search.isEmpty &&
        !source.any((m) => m.id == focused.id)) {
      source.insert(0, focused);
    }

    return source
        .where(
          (marker) =>
              _status.isEmpty ||
              marker.status.toLowerCase() == _status,
        )
        .toList();
  }

  void _fitMarkers(List<TrafficMapMarker> markers) {
    if (markers.isEmpty) return;

    if (markers.length == 1) {
      final loc = markers.first.location;

      _mapController.move(
        LatLng(loc.latitude, loc.longitude),
        14,
      );
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          for (final marker in markers)
            LatLng(
              marker.location.latitude,
              marker.location.longitude,
            ),
        ]),
        padding: const EdgeInsets.all(56),
      ),
    );
  }

  void _openDetails(TrafficMapMarker marker) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrafficProblemDetailsScreen(
          issueId: marker.id,
          service: _service,
        ),
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String detail, {
    bool clearSearch = false,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.muted,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: clearSearch
                    ? _clearSearch
                    : () => _load(),
                icon: Icon(
                  clearSearch
                      ? Icons.close
                      : Icons.refresh,
                ),
                label: Text(
                  clearSearch
                      ? 'Clear location search'
                      : 'Refresh map',
                ),
              ),
            ],
          ),
        ),
      );

  Widget _mapContent(TrafficMapPage page) {
    final markers = _matchingMarkers(page);

    final selected = _selected != null &&
            markers.any((m) => m.id == _selected!.id)
        ? _selected
        : null;

    final focused = widget.focusMarker;

    final hasFocused = focused != null &&
        markers.any((m) => m.id == focused.id) &&
        _search.isEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          color: AppColors.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'City Traffic Incident Map',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${markers.length} visible markers  •  ${page.total} matching reports',
                style: const TextStyle(
                  color: AppColors.muted,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  key: const Key('traffic-map-list-view'),
                  onPressed: _switchToList,
                  icon: const Icon(
                    Icons.view_list_outlined,
                  ),
                  label: const Text('List view'),
                ),
              ),
              if (page.total > page.items.length)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Only the latest 500 locations are loaded. Search to narrow results.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                key: const Key(
                  'traffic-map-location-search',
                ),
                controller: _locationSearch,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _applySearch(),
                decoration: InputDecoration(
                  hintText: 'Search city, street or report title',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_search.isNotEmpty ||
                          _locationSearch.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear location search',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                      IconButton(
                        tooltip: 'Search locations',
                        icon: const Icon(
                          Icons.arrow_forward,
                        ),
                        onPressed: _applySearch,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in _statuses) ...[
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
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: markers.isEmpty
              ? _message(
                  Icons.location_off_outlined,
                  'No matching traffic locations',
                  _search.isNotEmpty
                      ? 'Try a different city or street name.'
                      : 'No reports match this status, or they have no coordinates.',
                  clearSearch: _search.isNotEmpty,
                )
              : Stack(
                  children: [
                    FlutterMap(
                      // Refit the camera when the search or visible
                      // status changes.
                      key: ValueKey(
                        'traffic-map-$_search-$_status',
                      ),
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: focused != null && hasFocused
                            ? LatLng(
                                focused.location.latitude,
                                focused.location.longitude,
                              )
                            : const LatLng(7.8731, 80.7718),
                        initialZoom: hasFocused ? 14 : 7.5,
                        initialCameraFit:
                            hasFocused || markers.length < 2
                                ? null
                                : CameraFit.bounds(
                                    bounds: LatLngBounds.fromPoints([
                                      for (final m in markers)
                                        LatLng(
                                          m.location.latitude,
                                          m.location.longitude,
                                        ),
                                    ]),
                                    padding: const EdgeInsets.all(56),
                                  ),
                        onTap: (_, __) => setState(
                          () => _selected = null,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _tileUrl,
                          userAgentPackageName:
                              'lk.smartcity.ai_platform',
                        ),
                        MarkerLayer(
                          markers: [
                            for (final item in markers)
                              Marker(
                                point: LatLng(
                                  item.location.latitude,
                                  item.location.longitude,
                                ),
                                width: 48,
                                height: 48,
                                child: GestureDetector(
                                  key: Key(
                                    'traffic-map-marker-${item.id}',
                                  ),
                                  onTap: () => setState(
                                    () => _selected = item,
                                  ),
                                  child: Tooltip(
                                    message: item.title,
                                    child: Icon(
                                      Icons.location_on,
                                      color: _pinColor(item.status),
                                      size: selected?.id == item.id
                                          ? 48
                                          : 42,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SimpleAttributionWidget(
                          source: Text(
                            '© OpenStreetMap contributors',
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        elevation: 3,
                        borderRadius:
                            BorderRadius.circular(12),
                        child: IconButton(
                          tooltip:
                              'Fit visible traffic markers',
                          icon: const Icon(
                            Icons.center_focus_strong,
                            color: AppColors.primary,
                          ),
                          onPressed: () =>
                              _fitMarkers(markers),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (selected != null)
          Card(
            margin: const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              12,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selected.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close marker details',
                        onPressed: () => setState(
                          () => _selected = null,
                        ),
                        icon: const Icon(
                          Icons.close,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${trafficLabel(selected.status)} • '
                    '${trafficLabel(selected.priority)} priority',
                    style: const TextStyle(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected.location.address ??
                        selected.location.city ??
                        'Location shown on map',
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _openDetails(selected),
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 16,
                      ),
                      label: const Text(
                        'View report details',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Traffic Incident Map'),
          actions: [
            IconButton(
              onPressed: _switchToList,
              tooltip: 'Switch to List View',
              icon: const Icon(
                Icons.view_list_outlined,
              ),
            ),
            IconButton(
              onPressed: () => _load(
                keepSelection: false,
              ),
              tooltip: 'Refresh markers from MySQL',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 950,
              ),
              child: FutureBuilder<TrafficMapPage>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState !=
                      ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _message(
                      Icons.wifi_off_outlined,
                      'Unable to load the incident map',
                      '${snapshot.error}',
                    );
                  }

                  return _mapContent(snapshot.data!);
                },
              ),
            ),
          ),
        ),
      );
}
