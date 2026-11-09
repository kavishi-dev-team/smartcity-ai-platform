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
import '../../dashboard/providers/dashboard_provider.dart';
import '../../reporting/screens/report_details_screen.dart';
import '../../reporting/widgets/interactive_location_picker.dart';
import '../models/air_quality_model.dart';
import '../providers/safety_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/aqi_indicator.dart';
import '../widgets/safety_message_view.dart';
import 'air_quality_details_screen.dart';
import 'air_quality_history_screen.dart';

/// Entry point for the Islandwide Live Air Quality & Environmental Complaint Hub.
class AirQualityScreen extends StatelessWidget {
  const AirQualityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SafetyProvider()..loadAirQuality(),
      child: const _AirQualityView(),
    );
  }
}

void _openWithProvider(BuildContext context, Widget screen) {
  final provider = context.read<SafetyProvider>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          ChangeNotifierProvider.value(value: provider, child: screen),
    ),
  );
}

class _AirQualityView extends StatefulWidget {
  const _AirQualityView();

  @override
  State<_AirQualityView> createState() => _AirQualityViewState();
}

class _AirQualityViewState extends State<_AirQualityView> {
  final MapController _mapController = MapController();
  final TextEditingController _locationSearchCtrl = TextEditingController();
  final TextEditingController _cityFilterCtrl = TextEditingController();

  List<ResolvedLocation> _searchSuggestions = [];
  bool _isSearchingLocation = false;
  bool _isDetectingGps = false;
  Timer? _searchDebounce;

  String _selectedProvince = 'All';
  String _cityFilterQuery = '';
  String _sortMode = 'city'; // 'city', 'high_aqi', 'low_aqi'

  List<Map<String, dynamic>> _airComplaints = [];
  bool _loadingComplaints = true;
  int? _lastLoadedUserId;

  static const List<String> _provinces = [
    'All',
    'Western',
    'Central',
    'Southern',
    'Northern',
    'Eastern',
    'North Western',
    'North Central',
    'Uva',
    'Sabaragamuwa',
  ];

  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAirQualityComplaints();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().user?.id;
    if (userId != _lastLoadedUserId) {
      _lastLoadedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAirQualityComplaints();
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _locationSearchCtrl.dispose();
    _cityFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAirQualityComplaints() async {
    if (!mounted) return;
    setState(() => _loadingComplaints = true);
    try {
      final user = context.read<AuthProvider>().user;
      final isCitizen = user?.isCitizen ?? true;
      final queryParams = <String, String>{
        'category': 'all',
        'limit': '100',
      };
      if (isCitizen && user?.id != null) {
        queryParams['reported_by'] = '${user!.id}';
      }

      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/issues',
      ).replace(queryParameters: queryParams);

      final res = await http.get(uri).timeout(AppConfig.requestTimeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawItems = (data['items'] as List<dynamic>? ?? []);
        final filtered = rawItems
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((item) {
              final sub = (item['subcategory'] ?? '').toString().toLowerCase();
              final title = (item['title'] ?? '').toString().toLowerCase();
              final desc = (item['description'] ?? '').toString().toLowerCase();
              return sub == 'air_quality' ||
                  title.contains('air quality') ||
                  title.contains('aqi') ||
                  title.contains('smoke') ||
                  title.contains('pollution') ||
                  title.contains('dust') ||
                  title.contains('burning') ||
                  title.contains('fume') ||
                  desc.contains('air quality') ||
                  desc.contains('aqi:');
            })
            .toList();
        if (mounted) {
          setState(() {
            _airComplaints = filtered;
            _loadingComplaints = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingComplaints = false);
    }
  }

  void _onSearchQueryChanged(String value) {
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _isSearchingLocation = false;
      });
      return;
    }
    setState(() => _isSearchingLocation = true);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await LocationService.searchAddressOrTown(trimmed);
      if (!mounted) return;
      setState(() {
        _searchSuggestions = results;
        _isSearchingLocation = false;
      });
    });
  }

  Future<void> _pickAndCheckLocation({
    required double lat,
    required double lon,
    String? areaName,
    double zoom = 11.5,
  }) async {
    setState(() => _searchSuggestions = []);
    try {
      _mapController.move(LatLng(lat, lon), zoom);
    } catch (_) {}
    final p = context.read<SafetyProvider>();
    final reading = await p.checkLocationAirQuality(
      lat: lat,
      lon: lon,
      areaName: areaName,
    );
    if (!mounted || reading == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Live AQI in ${reading.area}: ${reading.aqi} (${reading.category})',
        ),
        backgroundColor: aqiColor(reading.aqi),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _useCurrentGpsLocation() async {
    setState(() => _isDetectingGps = true);
    try {
      final resolved = await LocationService.detectCurrentLocation();
      if (!mounted) return;
      _locationSearchCtrl.text = resolved.displayName;
      await _pickAndCheckLocation(
        lat: resolved.latitude,
        lon: resolved.longitude,
        areaName: '${resolved.address}, ${resolved.city}',
        zoom: 12.5,
      );
    } finally {
      if (mounted) {
        setState(() => _isDetectingGps = false);
      }
    }
  }

  void _selectExistingCity(AirQualityReading reading) {
    final p = context.read<SafetyProvider>();
    p.selectArea(reading.area);
    if (reading.latitude != null && reading.longitude != null) {
      try {
        _mapController.move(
          LatLng(reading.latitude!, reading.longitude!),
          11.0,
        );
      } catch (_) {}
    }
  }

  Future<void> _openAirQualityComplaintModal(
    BuildContext context,
    AirQualityReading current,
  ) async {
    final initialLoc = ResolvedLocation(
      displayName: current.area,
      address: current.area,
      city: current.district ?? current.area.split(',').last.trim(),
      latitude: current.latitude ?? 6.9271,
      longitude: current.longitude ?? 79.8612,
    );

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AirQualityComplaintSheet(
        initialReading: current,
        initialLocation: initialLoc,
      ),
    );

    if (submitted == true && mounted) {
      await _loadAirQualityComplaints();
      if (!context.mounted) return;
      final userId = context.read<AuthProvider>().user?.id;
      context.read<DashboardProvider>().loadCitizenDashboard(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SafetyProvider>();
    final current = p.selectedReading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sri Lanka Live Air Quality'),
        actions: [
          if (current != null)
            IconButton(
              tooltip: 'Report Air Quality Complaint',
              icon: const Icon(Icons.report_gmailerrorred_rounded),
              onPressed: () => _openAirQualityComplaintModal(context, current),
            ),
          IconButton(
            tooltip: 'Fetch Live Telemetry',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              p.loadAirQuality(refresh: true);
              _loadAirQualityComplaints();
            },
          ),
        ],
      ),
      floatingActionButton: current != null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => _openAirQualityComplaintModal(context, current),
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Report Air Complaint'),
            )
          : null,
      body: _buildBody(context, p, current),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SafetyProvider p,
    AirQualityReading? current,
  ) {
    if (p.isLoadingAir && p.readings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.airError != null && p.readings.isEmpty) {
      return SafetyMessageView(
        icon: Icons.cloud_off,
        message: p.airError!,
        actionLabel: 'Try again',
        onAction: () => p.loadAirQuality(refresh: true),
      );
    }
    if (current == null) {
      return SafetyMessageView(
        icon: Icons.air,
        message: 'No air quality data available yet.',
        actionLabel: 'Refresh',
        onAction: () => p.loadAirQuality(refresh: true),
      );
    }

    final filteredCities = p.readings.where((r) {
      if (_selectedProvince != 'All' &&
          (r.province ?? '').toLowerCase() != _selectedProvince.toLowerCase()) {
        return false;
      }
      if (_cityFilterQuery.trim().isNotEmpty) {
        final q = _cityFilterQuery.trim().toLowerCase();
        final matchArea = r.area.toLowerCase().contains(q);
        final matchDist = (r.district ?? '').toLowerCase().contains(q);
        final matchProv = (r.province ?? '').toLowerCase().contains(q);
        return matchArea || matchDist || matchProv;
      }
      return true;
    }).toList();

    if (_sortMode == 'high_aqi') {
      filteredCities.sort((a, b) => b.aqi.compareTo(a.aqi));
    } else if (_sortMode == 'low_aqi') {
      filteredCities.sort((a, b) => a.aqi.compareTo(b.aqi));
    } else {
      filteredCities.sort((a, b) => a.area.compareTo(b.area));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          p.loadAirQuality(refresh: true),
          _loadAirQualityComplaints(),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: [
          _buildIslandwideOverviewBanner(p, current),
          const SizedBox(height: 16),
          _buildInteractiveSriLankaMapCard(p, current),
          const SizedBox(height: 16),
          _buildSelectedLocationTelemetryCard(context, p, current),
          const SizedBox(height: 18),
          _buildAirQualityComplaintsSection(context, current),
          const SizedBox(height: 20),
          _buildAllSriLankaCitiesDirectory(p, current, filteredCities),
        ],
      ),
    );
  }

  Widget _buildIslandwideOverviewBanner(
    SafetyProvider p,
    AirQualityReading current,
  ) {
    final readings = p.readings;
    final avgAqi = readings.isEmpty
        ? current.aqi
        : (readings.map((r) => r.aqi).reduce((a, b) => a + b) / readings.length)
            .round();
    AirQualityReading cleanest = current;
    AirQualityReading highest = current;
    for (final r in readings) {
      if (r.aqi < cleanest.aqi) cleanest = r;
      if (r.aqi > highest.aqi) highest = r;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SRI LANKA NATIONAL AIR QUALITY GRID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live Open-Meteo CAMS Telemetry • ${readings.length} Cities Across All 25 Districts',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (p.isLoadingAir || p.isCheckingCustomLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _islandStatTile(
                  label: 'Sri Lanka Avg',
                  value: 'AQI $avgAqi',
                  sub: avgAqi <= 50 ? 'Good Islandwide' : 'Moderate',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectExistingCity(cleanest),
                  child: _islandStatTile(
                    label: 'Cleanest Air',
                    value: 'AQI ${cleanest.aqi}',
                    sub: cleanest.area,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectExistingCity(highest),
                  child: _islandStatTile(
                    label: 'Highest AQI',
                    value: 'AQI ${highest.aqi}',
                    sub: highest.area,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _islandStatTile({
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveSriLankaMapCard(
    SafetyProvider p,
    AirQualityReading current,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.explore_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick Any Location in Sri Lanka to Check Live AQI',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Search any town/address, use GPS, or tap anywhere on the Sri Lanka map',
                        style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    try {
                      _mapController.move(_sriLankaCenter, 7.2);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.zoom_out_map_rounded, size: 16),
                  label: const Text('Whole Island'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Address / Town Search + GPS Picker
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationSearchCtrl,
                    onChanged: _onSearchQueryChanged,
                    onSubmitted: (q) async {
                      if (q.trim().isEmpty) return;
                      final results =
                          await LocationService.searchAddressOrTown(q.trim());
                      if (results.isNotEmpty) {
                        final first = results.first;
                        _locationSearchCtrl.text = first.displayName;
                        await _pickAndCheckLocation(
                          lat: first.latitude,
                          lon: first.longitude,
                          areaName:
                              first.address != first.city
                                  ? '${first.address}, ${first.city}'
                                  : first.city,
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Search any Sri Lankan town or street (e.g. Kandy, Digana, Jaffna)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      suffixIcon: _isSearchingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _locationSearchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _locationSearchCtrl.clear();
                                    setState(() => _searchSuggestions = []);
                                  },
                                )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lightBlue,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: _isDetectingGps ? null : _useCurrentGpsLocation,
                  icon: _isDetectingGps
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('GPS'),
                ),
              ],
            ),
            if (_searchSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                constraints: const BoxConstraints(maxHeight: 190),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = _searchSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.place_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        s.city,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        s.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Text(
                        'Check AQI',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () {
                        _locationSearchCtrl.text = s.displayName;
                        final label = s.address.toLowerCase() !=
                                s.city.toLowerCase()
                            ? '${s.address}, ${s.city}'
                            : s.city;
                        _pickAndCheckLocation(
                          lat: s.latitude,
                          lon: s.longitude,
                          areaName: label,
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            // Interactive Sri Lanka Map
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 310,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: current.latitude != null &&
                                current.longitude != null
                            ? LatLng(current.latitude!, current.longitude!)
                            : _sriLankaCenter,
                        initialZoom: 7.4,
                        onTap: (tapPosition, point) {
                          _pickAndCheckLocation(
                            lat: point.latitude,
                            lon: point.longitude,
                            zoom: 11.5,
                          );
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.smartcity.app',
                        ),
                        MarkerLayer(
                          markers: [
                            for (final r in p.readings)
                              if (r.latitude != null && r.longitude != null)
                                Marker(
                                  point: LatLng(r.latitude!, r.longitude!),
                                  width: r.area == current.area ? 80 : 64,
                                  height: r.area == current.area ? 50 : 42,
                                  child: GestureDetector(
                                    onTap: () => _selectExistingCity(r),
                                    child: Tooltip(
                                      message:
                                          '${r.area}: AQI ${r.aqi} (${r.category})',
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: aqiColor(r.aqi),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: r.area == current.area
                                                ? 2.5
                                                : 1.5,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 1.5),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${r.aqi}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.area == current.area
                                                    ? 13
                                                    : 11,
                                                fontWeight: FontWeight.w900,
                                                height: 1.1,
                                              ),
                                            ),
                                            Text(
                                              r.area.split(',').first,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 16,
                              color: aqiColor(current.aqi),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selected: ${current.area} • AQI ${current.aqi} (${current.category})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () =>
                                  _openAirQualityComplaintModal(context, current),
                              child: const Text('Complain Here'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLocationTelemetryCard(
    BuildContext context,
    SafetyProvider p,
    AirQualityReading current,
  ) {
    final subtitleParts = <String>[
      if (current.district != null && current.district!.isNotEmpty)
        '${current.district} District',
      if (current.province != null && current.province!.isNotEmpty)
        '${current.province} Province',
      if (current.latitude != null && current.longitude != null)
        '${current.latitude!.toStringAsFixed(4)}, ${current.longitude!.toStringAsFixed(4)}',
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: aqiColor(current.aqi).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: aqiColor(current.aqi),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.area,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      if (subtitleParts.isNotEmpty)
                        Text(
                          subtitleParts.join(' • '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sensors_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'LIVE API',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: AqiIndicator(
                aqi: current.aqi,
                category: current.category,
                size: 185,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: aqiColor(current.aqi).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: aqiColor(current.aqi).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    color: aqiColor(current.aqi),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      current.healthRecommendation,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.text,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Live Atmospheric Pollutants',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            PollutantList(reading: current),
            const SizedBox(height: 10),
            Text(
              'Updated: ${formatDateTime(current.recordedAt)} • ${current.source ?? "Open-Meteo CAMS Live API"}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    _openAirQualityComplaintModal(context, current),
                icon: const Icon(Icons.add_alert_rounded),
                label: Text('Report Air Quality Complaint in ${current.area.split(",").first}'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWithProvider(
                      context,
                      const AirQualityDetailsScreen(),
                    ),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Full Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWithProvider(
                      context,
                      const AirQualityHistoryScreen(),
                    ),
                    icon: const Icon(Icons.show_chart),
                    label: const Text('24h / 30d Trends'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirQualityComplaintsSection(
    BuildContext context,
    AirQualityReading current,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Air Quality Complaints in Places',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Report smoke, garbage burning, factory emissions, or dust hazards',
                        style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lightBlue,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: () =>
                      _openAirQualityComplaintModal(context, current),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                  label: const Text('New Complaint'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingComplaints)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_airComplaints.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.air_rounded,
                      color: AppColors.muted,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No air quality complaints submitted yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pick any town or street above and tap "New Complaint" to report smoke, burning, dust, or odor issues.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (final item in _airComplaints.take(6))
                    _buildAirComplaintTile(context, item),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirComplaintTile(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final id = item['id'] is int
        ? item['id'] as int
        : int.tryParse(item['id'].toString()) ?? 0;
    final status = (item['status'] ?? 'reported').toString();
    final priority = (item['priority'] ?? 'high').toString();
    final locs = item['locations'] as List<dynamic>? ?? [];
    String city = '';
    String address = '';
    double? lat;
    double? lon;
    if (locs.isNotEmpty && locs.first is Map) {
      final firstLoc = locs.first as Map;
      city = (firstLoc['city'] ?? '').toString();
      address = (firstLoc['address'] ?? '').toString();
      lat = (firstLoc['latitude'] as num?)?.toDouble();
      lon = (firstLoc['longitude'] as num?)?.toDouble();
    }
    final placeText = address.isNotEmpty &&
            city.isNotEmpty &&
            !address.toLowerCase().contains(city.toLowerCase())
        ? '$address, $city'
        : (address.isNotEmpty ? address : city);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.16),
          child: const Icon(
            Icons.masks_rounded,
            color: AppColors.warning,
            size: 20,
          ),
        ),
        title: Text(
          (item['title'] ?? 'Air Quality Complaint').toString(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: AppColors.text,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (placeText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        placeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 3),
            Text(
              '${status.replaceAll("_", " ").toUpperCase()} • Priority: ${priority.toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lat != null && lon != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Check Live AQI at this Complaint Location',
                icon: const Icon(
                  Icons.radar_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () => _pickAndCheckLocation(
                  lat: lat!,
                  lon: lon!,
                  areaName: placeText.isNotEmpty ? placeText : null,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ReportDetailsScreen(issueId: id, initialData: item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllSriLankaCitiesDirectory(
    SafetyProvider p,
    AirQualityReading current,
    List<AirQualityReading> filteredCities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'All Sri Lanka Cities Live AQI (${filteredCities.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            DropdownButton<String>(
              value: _sortMode,
              underline: const SizedBox.shrink(),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
              items: const [
                DropdownMenuItem(value: 'city', child: Text('Sort: A–Z')),
                DropdownMenuItem(
                  value: 'high_aqi',
                  child: Text('Sort: Highest AQI'),
                ),
                DropdownMenuItem(
                  value: 'low_aqi',
                  child: Text('Sort: Cleanest AQI'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _sortMode = v);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cityFilterCtrl,
          onChanged: (v) => setState(() => _cityFilterQuery = v),
          decoration: InputDecoration(
            hintText: 'Filter cities or districts (e.g. Colombo, Kandy, Galle)...',
            prefixIcon: const Icon(Icons.filter_list_rounded),
            isDense: true,
            suffixIcon: _cityFilterQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _cityFilterCtrl.clear();
                      setState(() => _cityFilterQuery = '');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.88, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _provinces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prov = _provinces[index];
                final isSelected = _selectedProvince == prov;
                return InkWell(
                  onTap: () => setState(() => _selectedProvince = prov),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.lightBlue.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      prov == 'All' ? 'All Sri Lanka' : '$prov Prov.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.text,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final r in filteredCities)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              onTap: () => _selectExistingCity(r),
              leading: CircleAvatar(
                backgroundColor: aqiColor(r.aqi),
                child: Text(
                  '${r.aqi}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              title: Text(
                r.area,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  r.category,
                  if (r.district != null) '${r.district} Dist.',
                  if (r.pm25 != null) 'PM2.5: ${r.pm25!.toStringAsFixed(1)}',
                ].join(' • '),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Report Air Quality Complaint in ${r.area}',
                    icon: const Icon(
                      Icons.campaign_outlined,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    onPressed: () {
                      p.selectArea(r.area);
                      _openAirQualityComplaintModal(context, r);
                    },
                  ),
                  const SizedBox(width: 4),
                  r.area == current.area
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 20)
                      : const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AirQualityComplaintSheet extends StatefulWidget {
  final AirQualityReading initialReading;
  final ResolvedLocation initialLocation;

  const _AirQualityComplaintSheet({
    required this.initialReading,
    required this.initialLocation,
  });

  @override
  State<_AirQualityComplaintSheet> createState() =>
      _AirQualityComplaintSheetState();
}

class _AirQualityComplaintSheetState extends State<_AirQualityComplaintSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late ResolvedLocation _pickedLocation;
  String _priority = 'high';
  bool _submitting = false;

  static const List<({String label, String title, String desc, String priority})>
      _templates = [
    (
      label: 'Open Garbage / Plastic Burning',
      title: 'Toxic smoke from open plastic & garbage burning',
      desc:
          'Open burning of mixed municipal waste and plastics releasing dense black smoke and hazardous fumes across residential houses.',
      priority: 'high',
    ),
    (
      label: 'Factory / Industrial Smoke',
      title: 'Unfiltered industrial smoke emission hazard',
      desc:
          'Continuous heavy dark smoke and chemical odor emitted into surrounding neighborhood air.',
      priority: 'critical',
    ),
    (
      label: 'Road / Construction Dust',
      title: 'Severe airborne dust pollution from road/building site',
      desc:
          'Uncontrolled fine particulate dust cloud reducing visibility and causing breathing discomfort for pedestrians and residents.',
      priority: 'medium',
    ),
    (
      label: 'Vehicle Exhaust Smog',
      title: 'Heavy vehicle exhaust smoke & roadside smog buildup',
      desc:
          'Excessive black diesel exhaust emissions creating severe localized air pollution along the main road corridor.',
      priority: 'high',
    ),
    (
      label: 'Chemical / Toxic Odor',
      title: 'Strong chemical / noxious odor in public area',
      desc:
          'Persistent pungent chemical or noxious gas smell detected in the area requiring environmental inspection.',
      priority: 'critical',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    _titleCtrl = TextEditingController(
      text: 'Air quality hazard reported in ${widget.initialReading.area}',
    );
    _descCtrl = TextEditingController(
      text:
          'Live Telemetry at time of complaint: AQI ${widget.initialReading.aqi} (${widget.initialReading.category})'
          '${widget.initialReading.pm25 != null ? ", PM2.5: ${widget.initialReading.pm25} µg/m³" : ""}. '
          'Please inspect localized smoke/air pollution at this location.',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final userId = context.read<AuthProvider>().user?.id;
      final telemetryNote =
          '\n\n[Live AQI Telemetry: AQI ${widget.initialReading.aqi} (${widget.initialReading.category})'
          '${widget.initialReading.pm25 != null ? " | PM2.5: ${widget.initialReading.pm25} µg/m³" : ""}'
          '${widget.initialReading.pm10 != null ? " | PM10: ${widget.initialReading.pm10} µg/m³" : ""}]';

      final descriptionText = _descCtrl.text.trim().contains('AQI')
          ? _descCtrl.text.trim()
          : '${_descCtrl.text.trim()}$telemetryNote';

      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/issues'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': _titleCtrl.text.trim(),
              'description': descriptionText,
              'category': 'complaint',
              'subcategory': 'air_quality',
              'priority': _priority,
              'reported_by': userId,
              'city': _pickedLocation.city,
              'address': _pickedLocation.address,
              'latitude': _pickedLocation.latitude,
              'longitude': _pickedLocation.longitude,
            }),
          )
          .timeout(AppConfig.requestTimeout);

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception('Failed (${res.statusCode})');
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Air quality complaint submitted for ${_pickedLocation.address}, ${_pickedLocation.city}!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit air quality complaint: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 36),
      padding: EdgeInsets.fromLTRB(18, 16, 18, bottomInset + 20),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.air_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Air Quality Complaint',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${widget.initialReading.area} • Live AQI ${widget.initialReading.aqi} (${widget.initialReading.category})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '1. QUICK POLLUTION TYPE TEMPLATES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _templates)
                    ActionChip(
                      avatar: const Icon(
                        Icons.bolt_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        t.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _titleCtrl.text =
                              '${t.title} (${_pickedLocation.city})';
                          _descCtrl.text =
                              '${t.desc}\nLive AQI at location: ${widget.initialReading.aqi} (${widget.initialReading.category}).';
                          _priority = t.priority;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '2. PIN EXACT POLLUTION / COMPLAINT LOCATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              InteractiveLocationPicker(
                initialLocation: _pickedLocation,
                onLocationChanged: (loc) {
                  setState(() => _pickedLocation = loc);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Complaint Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pollution Details & Health Impact',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Enter complaint details'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Severity / Priority',
                  prefixIcon: Icon(Icons.priority_high_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(
                    value: 'critical',
                    child: Text('Critical Hazard'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _priority = v);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting
                        ? 'Submitting Air Quality Complaint...'
                        : 'Submit Air Quality Complaint',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}