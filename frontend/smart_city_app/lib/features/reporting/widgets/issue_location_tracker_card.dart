import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'quick_issue_report_sheet.dart';

class IssueLocationTrackerCard extends StatefulWidget {
  final String title;
  final String category;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? priority;
  final String? status;

  const IssueLocationTrackerCard({
    super.key,
    required this.title,
    this.category = 'all',
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.priority,
    this.status,
  });

  @override
  State<IssueLocationTrackerCard> createState() =>
      _IssueLocationTrackerCardState();
}

class _IssueLocationTrackerCardState extends State<IssueLocationTrackerCard> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late double _issueLat;
  late double _issueLon;
  late String _resolvedAddress;
  late String _resolvedCity;
  bool _resolving = false;
  ResolvedLocation? _searchedTarget;

  @override
  void initState() {
    super.initState();
    _resolvedAddress = (widget.address ?? '').trim();
    _resolvedCity = (widget.city ?? '').trim();
    final hasValidCoords = widget.latitude != null &&
        widget.longitude != null &&
        widget.latitude != 0 &&
        widget.longitude != 0;

    if (hasValidCoords) {
      _issueLat = widget.latitude!;
      _issueLon = widget.longitude!;
      if (_resolvedAddress.isEmpty && _resolvedCity.isEmpty) {
        _reverseGeocodeIssueCoords();
      }
    } else {
      _issueLat = 6.9271;
      _issueLon = 79.8612;
      _geocodeFromAddressOrTown();
    }
  }

  @override
  void didUpdateWidget(covariant IssueLocationTrackerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude ||
        widget.address != oldWidget.address ||
        widget.city != oldWidget.city) {
      final hasValidCoords = widget.latitude != null &&
          widget.longitude != null &&
          widget.latitude != 0 &&
          widget.longitude != 0;
      if (hasValidCoords) {
        setState(() {
          _issueLat = widget.latitude!;
          _issueLon = widget.longitude!;
          if ((widget.address ?? '').trim().isNotEmpty) {
            _resolvedAddress = widget.address!.trim();
          }
          if ((widget.city ?? '').trim().isNotEmpty) {
            _resolvedCity = widget.city!.trim();
          }
        });
        _moveCamera(_issueLat, _issueLon);
      } else {
        _resolvedAddress = (widget.address ?? '').trim();
        _resolvedCity = (widget.city ?? '').trim();
        _geocodeFromAddressOrTown();
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _moveCamera(double lat, double lon, {double zoom = 14.5}) {
    try {
      _mapController.move(LatLng(lat, lon), zoom);
    } catch (_) {}
  }

  Future<void> _geocodeFromAddressOrTown() async {
    final query = [_resolvedAddress, _resolvedCity]
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'not available')
        .join(', ');
    if (query.isEmpty) return;

    setState(() => _resolving = true);
    try {
      final matches = await LocationService.searchAddressOrTown(query);
      if (!mounted) return;
      if (matches.isNotEmpty) {
        final best = matches.first;
        setState(() {
          _issueLat = best.latitude;
          _issueLon = best.longitude;
          if (_resolvedAddress.isEmpty) _resolvedAddress = best.address;
          if (_resolvedCity.isEmpty) _resolvedCity = best.city;
        });
        _moveCamera(best.latitude, best.longitude);
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _reverseGeocodeIssueCoords() async {
    setState(() => _resolving = true);
    try {
      final loc = await LocationService.reverseGeocode(_issueLat, _issueLon);
      if (!mounted) return;
      setState(() {
        _resolvedAddress = loc.address;
        _resolvedCity = loc.city;
      });
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _trackSearchAddress(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _resolving = true);
    try {
      final matches = await LocationService.searchAddressOrTown(q);
      if (!mounted) return;
      if (matches.isNotEmpty) {
        setState(() => _searchedTarget = matches.first);
        _moveCamera(matches.first.latitude, matches.first.longitude, zoom: 14.5);
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationLabel = [
      if (_resolvedAddress.isNotEmpty) _resolvedAddress,
      if (_resolvedCity.isNotEmpty &&
          !_resolvedAddress
              .toLowerCase()
              .contains(_resolvedCity.toLowerCase()))
        _resolvedCity,
    ].join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_searching_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Problem Location Tracker',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      locationLabel.isEmpty
                          ? 'Tracked on Smart City GIS Map'
                          : locationLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_resolving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Coordinate & Town Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _infoBadge(
                Icons.gps_fixed_rounded,
                '${_issueLat.toStringAsFixed(4)}, ${_issueLon.toStringAsFixed(4)}',
                AppColors.primary,
              ),
              if (_resolvedCity.isNotEmpty)
                _infoBadge(
                  Icons.location_city_rounded,
                  _resolvedCity,
                  AppColors.cyan,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Search any address or town to locate on map
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _trackSearchAddress,
                  decoration: InputDecoration(
                    hintText: 'Track another address or town on map...',
                    prefixIcon: const Icon(
                      Icons.travel_explore_rounded,
                      size: 19,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchedTarget == null
                        ? null
                        : IconButton(
                            tooltip: 'Reset to problem pin',
                            icon: const Icon(Icons.close, size: 17),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchedTarget = null);
                              _moveCamera(_issueLat, _issueLon);
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _trackSearchAddress(_searchController.text),
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('Locate'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Interactive Map
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 215,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_issueLat, _issueLon),
                      initialZoom: 14.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'lk.smartcity.ai_platform',
                      ),
                      MarkerLayer(
                        markers: [
                          // Reported Problem Pin
                          Marker(
                            point: LatLng(_issueLat, _issueLon),
                            width: 56,
                            height: 56,
                            child: Tooltip(
                              message: widget.title,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.report_problem_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Searched Address/Town Target Pin
                          if (_searchedTarget != null)
                            Marker(
                              point: LatLng(
                                _searchedTarget!.latitude,
                                _searchedTarget!.longitude,
                              ),
                              width: 52,
                              height: 52,
                              child: Tooltip(
                                message: _searchedTarget!.displayName,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Column(
                      children: [
                        _miniMapBtn(
                          Icons.add,
                          'Zoom in',
                          () => _moveCamera(
                            _mapController.camera.center.latitude,
                            _mapController.camera.center.longitude,
                            zoom: _mapController.camera.zoom + 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _miniMapBtn(
                          Icons.remove,
                          'Zoom out',
                          () => _moveCamera(
                            _mapController.camera.center.latitude,
                            _mapController.camera.center.longitude,
                            zoom: _mapController.camera.zoom - 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _miniMapBtn(
                          Icons.center_focus_strong_rounded,
                          'Focus problem pin',
                          () => _moveCamera(_issueLat, _issueLon),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _moveCamera(_issueLat, _issueLon),
                icon: const Icon(Icons.pin_drop_outlined, size: 17),
                label: const Text('Center on Problem Pin'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DomainLocationTrackerScreen(
                        category: widget.category,
                        initialFocus: ResolvedLocation(
                          displayName: locationLabel.isEmpty
                              ? widget.title
                              : locationLabel,
                          address: _resolvedAddress.isEmpty
                              ? widget.title
                              : _resolvedAddress,
                          city: _resolvedCity.isEmpty
                              ? 'Colombo'
                              : _resolvedCity,
                          latitude: _issueLat,
                          longitude: _issueLon,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_full_rounded, size: 16),
                label: const Text('Full Map Tracker'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMapBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 17, color: AppColors.primaryDark),
          ),
        ),
      ),
    );
  }
}

/// Full-screen interactive domain problem location tracker that lets users:
/// 1) View all reported problem pins for the domain (or their own reports for citizens)
/// 2) Search & track any entered street address or town in Sri Lanka
/// 3) Tap anywhere or on a tracked address/town to submit a new report at that exact spot
class DomainLocationTrackerScreen extends StatefulWidget {
  final String category;
  final String? subcategory;
  final ResolvedLocation? initialFocus;

  const DomainLocationTrackerScreen({
    super.key,
    this.category = 'all',
    this.subcategory,
    this.initialFocus,
  });

  @override
  State<DomainLocationTrackerScreen> createState() =>
      _DomainLocationTrackerScreenState();
}

class _DomainLocationTrackerScreenState
    extends State<DomainLocationTrackerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _markers = [];
  Map<String, dynamic>? _selectedIssue;
  ResolvedLocation? _trackedAddress;
  List<ResolvedLocation> _suggestions = [];
  bool _loading = true;
  bool _locating = false;
  Timer? _debounce;

  static const Map<String, String> _titles = {
    'waste': 'Waste Problem Location Tracker',
    'energy': 'Energy Problem Location Tracker',
    'water': 'Water & Leakage Location Tracker',
    'traffic': 'Traffic Incident Location Tracker',
    'safety': 'Public Safety Location Tracker',
    'complaint': 'Citizen Complaint Location Tracker',
    'all': 'Smart City Problem Location Tracker',
  };

  @override
  void initState() {
    super.initState();
    _trackedAddress = widget.initialFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarkers());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final user = context.read<AuthProvider>().user;
      final reportedBy = (user != null && user.isCitizen) ? user.id : null;
      final queryParams = <String, String>{
        'category': widget.category,
        if (widget.subcategory != null) 'subcategory': widget.subcategory!,
        if (reportedBy != null) 'reported_by': '$reportedBy',
      };
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/issues/map')
          .replace(queryParameters: queryParams);
      final response =
          await http.get(uri).timeout(AppConfig.requestTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final items = decoded['items'] as List<dynamic>? ?? [];
        _markers = items
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((m) => m['latitude'] != null && m['longitude'] != null)
            .toList();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);

    if (_trackedAddress != null) {
      _moveCamera(_trackedAddress!.latitude, _trackedAddress!.longitude,
          zoom: 14.5);
    } else if (_markers.isNotEmpty) {
      final first = _markers.first;
      _moveCamera(
        (first['latitude'] as num).toDouble(),
        (first['longitude'] as num).toDouble(),
        zoom: 12.5,
      );
    }
  }

  void _moveCamera(double lat, double lon, {double zoom = 14.0}) {
    try {
      _mapController.move(LatLng(lat, lon), zoom);
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _suggestions = LocationService.localSearch(q).take(5).toList();
    });
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await LocationService.searchAddressOrTown(q);
      if (!mounted) return;
      if (_searchController.text.trim() == q) {
        setState(() => _suggestions = results.take(6).toList());
      }
    });
  }

  Future<void> _trackAddressOrTown(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _locating = true;
      _suggestions = [];
    });
    try {
      final results = await LocationService.searchAddressOrTown(q);
      if (!mounted) return;
      if (results.isNotEmpty) {
        final best = results.first;
        setState(() {
          _trackedAddress = best;
          _selectedIssue = null;
        });
        _moveCamera(best.latitude, best.longitude, zoom: 14.5);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _locating = true;
      _selectedIssue = null;
      _suggestions = [];
    });
    try {
      final resolved = await LocationService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      setState(() => _trackedAddress = resolved);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportCategory =
        widget.category == 'all' ? 'waste' : widget.category;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_titles[widget.category] ?? 'Problem Location Tracker'),
        actions: [
          IconButton(
            tooltip: 'Report Problem Here',
            onPressed: () => QuickIssueReportSheet.show(
              context,
              initialCategory: reportCategory,
              initialSubcategory: widget.subcategory,
              initialLocation: _trackedAddress,
              onSubmitted: _loadMarkers,
            ),
            icon: const Icon(Icons.add_location_alt_rounded),
          ),
          IconButton(
            tooltip: 'Refresh Map',
            onPressed: _loadMarkers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => QuickIssueReportSheet.show(
          context,
          initialCategory: reportCategory,
          initialSubcategory: widget.subcategory,
          initialLocation: _trackedAddress,
          onSubmitted: _loadMarkers,
        ),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(
          _trackedAddress != null
              ? 'Report in ${_trackedAddress!.city}'
              : 'Report New Problem',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Top Address / Town Search Panel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _trackAddressOrTown,
                        decoration: InputDecoration(
                          hintText:
                              'Enter address, street, or town to track (e.g. Kandy, Matara)...',
                          prefixIcon: const Icon(
                            Icons.travel_explore_rounded,
                            color: AppColors.primary,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _suggestions = []);
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _locating
                          ? null
                          : () => _trackAddressOrTown(_searchController.text),
                      icon: _locating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.gps_fixed_rounded, size: 18),
                      label: const Text('Track'),
                    ),
                  ],
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.place_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          title: Text(
                            '${s.address}, ${s.city}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${s.latitude.toStringAsFixed(4)}, ${s.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            _searchController.text = '${s.address}, ${s.city}';
                            setState(() {
                              _trackedAddress = s;
                              _suggestions = [];
                            });
                            _moveCamera(s.latitude, s.longitude, zoom: 14.5);
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.pin_drop_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _trackedAddress != null
                            ? 'Tracked: ${_trackedAddress!.address}, ${_trackedAddress!.city} (${_trackedAddress!.latitude.toStringAsFixed(4)}, ${_trackedAddress!.longitude.toStringAsFixed(4)})'
                            : '${_markers.length} tracked problem location(s) • Tap map or search any town',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _trackedAddress != null
                              ? LatLng(
                                  _trackedAddress!.latitude,
                                  _trackedAddress!.longitude,
                                )
                              : const LatLng(6.9271, 79.8612),
                          initialZoom: 12.5,
                          onTap: (_, point) => _onMapTap(point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'lk.smartcity.ai_platform',
                          ),
                          MarkerLayer(
                            markers: [
                              for (final m in _markers)
                                Marker(
                                  point: LatLng(
                                    (m['latitude'] as num).toDouble(),
                                    (m['longitude'] as num).toDouble(),
                                  ),
                                  width: 48,
                                  height: 48,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedIssue = m),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      size: 42,
                                      color: _priorityColor(
                                        (m['priority'] ?? 'medium').toString(),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_trackedAddress != null)
                                Marker(
                                  point: LatLng(
                                    _trackedAddress!.latitude,
                                    _trackedAddress!.longitude,
                                  ),
                                  width: 56,
                                  height: 56,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.my_location_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_selectedIssue != null)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 76,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (_selectedIssue!['title'] ??
                                                  'Reported Issue')
                                              .toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => setState(
                                          () => _selectedIssue = null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_selectedIssue!['address'] ?? ''}, ${_selectedIssue!['city'] ?? ''}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${(_selectedIssue!['status'] ?? 'reported').toString().replaceAll('_', ' ').toUpperCase()} • Priority: ${(_selectedIssue!['priority'] ?? 'medium').toString().toUpperCase()}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
