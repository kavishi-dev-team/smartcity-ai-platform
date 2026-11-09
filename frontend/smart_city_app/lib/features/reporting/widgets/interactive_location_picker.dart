import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';

class InteractiveLocationPicker extends StatefulWidget {
  final ResolvedLocation initialLocation;
  final ValueChanged<ResolvedLocation> onLocationChanged;

  const InteractiveLocationPicker({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
  });

  @override
  State<InteractiveLocationPicker> createState() =>
      _InteractiveLocationPickerState();
}

class _InteractiveLocationPickerState extends State<InteractiveLocationPicker> {
  final MapController _mapController = MapController();
  late final TextEditingController _searchController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;

  late double _latitude;
  late double _longitude;
  bool _locating = false;
  List<ResolvedLocation> _suggestions = [];
  Timer? _debounce;

  static const List<String> _featuredTowns = [
    'Colombo 3',
    'Colombo 4',
    'Colombo 7',
    'Dehiwala',
    'Nugegoda',
    'Rajagiriya',
    'Malabe',
    'Negombo',
    'Gampaha',
    'Kandy',
    'Galle',
    'Matara',
    'Kurunegala',
    'Anuradhapura',
    'Jaffna',
    'Ratnapura',
    'Badulla',
    'Nuwara Eliya',
  ];

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLocation.latitude;
    _longitude = widget.initialLocation.longitude;
    _cityController = TextEditingController(text: widget.initialLocation.city);
    _addressController =
        TextEditingController(text: widget.initialLocation.address);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _emitCurrent() {
    final city = _cityController.text.trim().isEmpty
        ? 'Colombo'
        : _cityController.text.trim();
    final address = _addressController.text.trim().isEmpty
        ? city
        : _addressController.text.trim();
    widget.onLocationChanged(
      ResolvedLocation(
        displayName: '$address, $city',
        address: address,
        city: city,
        latitude: _latitude,
        longitude: _longitude,
      ),
    );
  }

  void _moveCamera(double lat, double lon, {double zoom = 14.5}) {
    try {
      _mapController.move(LatLng(lat, lon), zoom);
    } catch (_) {}
  }

  void _applyResolvedLocation(ResolvedLocation loc, {bool clearSuggestions = true}) {
    setState(() {
      _latitude = loc.latitude;
      _longitude = loc.longitude;
      _cityController.text = loc.city;
      _addressController.text = loc.address;
      if (clearSuggestions) {
        _suggestions = [];
      }
    });
    _moveCamera(loc.latitude, loc.longitude);
    _emitCurrent();
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

  Future<void> _trackQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() => _locating = true);
    try {
      final results = await LocationService.searchAddressOrTown(q);
      if (!mounted) return;
      if (results.isNotEmpty) {
        _applyResolvedLocation(results.first);
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _trackEnteredAddressAndTown() async {
    final addr = _addressController.text.trim();
    final town = _cityController.text.trim();
    final combined = [addr, town].where((s) => s.isNotEmpty).join(', ');
    if (combined.isEmpty) return;

    setState(() => _locating = true);
    try {
      final results = await LocationService.searchAddressOrTown(combined);
      if (!mounted) return;
      if (results.isNotEmpty) {
        final best = results.first;
        setState(() {
          _latitude = best.latitude;
          _longitude = best.longitude;
          if (_cityController.text.trim().isEmpty) {
            _cityController.text = best.city;
          }
          if (_addressController.text.trim().isEmpty) {
            _addressController.text = best.address;
          }
          _suggestions = [];
        });
        _moveCamera(best.latitude, best.longitude);
        _emitCurrent();
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
      _locating = true;
      _suggestions = [];
    });
    _emitCurrent();

    try {
      final resolved = await LocationService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      setState(() {
        _cityController.text = resolved.city;
        _addressController.text = resolved.address;
      });
      _emitCurrent();
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
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
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problem Location Tracker',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'Search any town/address or tap directly on the map to pin',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_locating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Address / Town Search Input + Track Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _trackQuery,
                  decoration: InputDecoration(
                    hintText: 'Enter address, street, or town (e.g. Kandy, Galle Rd)...',
                    prefixIcon: const Icon(
                      Icons.travel_explore_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _suggestions = []);
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
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
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _locating
                    ? null
                    : () => _trackQuery(_searchController.text),
                icon: const Icon(Icons.gps_fixed_rounded, size: 17),
                label: const Text('Track'),
              ),
            ],
          ),

          // Live Autocomplete Suggestions Dropdown
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 165),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final loc = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    title: Text(
                      loc.address,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                    subtitle: Text(
                      '${loc.city} • ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                    onTap: () {
                      _searchController.text = '${loc.address}, ${loc.city}';
                      _applyResolvedLocation(loc);
                    },
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Quick Town Selector Chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredTowns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final town = _featuredTowns[index];
                final isSelected = _cityController.text
                        .trim()
                        .toLowerCase() ==
                    town.toLowerCase();
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      isSelected ? AppColors.lightBlue : AppColors.card,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  avatar: Icon(
                    Icons.location_city_rounded,
                    size: 14,
                    color: isSelected ? AppColors.primary : AppColors.muted,
                  ),
                  label: Text(
                    town,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryDark : AppColors.text,
                    ),
                  ),
                  onPressed: () => _trackQuery(town),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Interactive Map View
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 205,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_latitude, _longitude),
                      initialZoom: 14.0,
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
                          Marker(
                            point: LatLng(_latitude, _longitude),
                            width: 56,
                            height: 56,
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
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Top-left live GPS pill
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 52,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed_rounded,
                            color: AppColors.skyBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tracked: ${_cityController.text.isEmpty ? "Colombo" : _cityController.text} (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Zoom & recenter controls
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Column(
                      children: [
                        _mapMiniButton(
                          icon: Icons.add,
                          tooltip: 'Zoom in',
                          onTap: () => _moveCamera(
                            _mapController.camera.center.latitude,
                            _mapController.camera.center.longitude,
                            zoom: _mapController.camera.zoom + 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _mapMiniButton(
                          icon: Icons.remove,
                          tooltip: 'Zoom out',
                          onTap: () => _moveCamera(
                            _mapController.camera.center.latitude,
                            _mapController.camera.center.longitude,
                            zoom: _mapController.camera.zoom - 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _mapMiniButton(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Center on pin',
                          onTap: () => _moveCamera(_latitude, _longitude),
                        ),
                      ],
                    ),
                  ),
                  // Bottom instruction bar
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Tap anywhere on map to move problem pin',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Editable Town/City & Street/Landmark synchronized with Map
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: _cityController,
                  onChanged: (_) => _emitCurrent(),
                  onFieldSubmitted: (_) => _trackEnteredAddressAndTown(),
                  decoration: const InputDecoration(
                    labelText: 'Town / City',
                    hintText: 'e.g., Kandy, Colombo 4',
                    prefixIcon: Icon(Icons.location_city_rounded, size: 18),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter town/city' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: TextFormField(
                  controller: _addressController,
                  onChanged: (_) => _emitCurrent(),
                  onFieldSubmitted: (_) => _trackEnteredAddressAndTown(),
                  decoration: const InputDecoration(
                    labelText: 'Street Address / Landmark',
                    hintText: 'e.g., 42 Galle Rd near junction',
                    prefixIcon: Icon(Icons.signpost_outlined, size: 18),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter address' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _locating ? null : _trackEnteredAddressAndTown,
              icon: const Icon(Icons.pin_drop_outlined, size: 16),
              label: const Text(
                'Locate Entered Address / Town on Map',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapMiniButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
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
