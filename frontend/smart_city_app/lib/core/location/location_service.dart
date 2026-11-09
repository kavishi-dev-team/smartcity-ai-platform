import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ResolvedLocation {
  final String displayName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;

  const ResolvedLocation({
    required this.displayName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  factory ResolvedLocation.fromJson(Map<String, dynamic> json) {
    return ResolvedLocation(
      displayName: (json['display_name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? 'Colombo').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 6.9271,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 79.8612,
    );
  }
}

class LocationService {
  LocationService._();

  static const List<ResolvedLocation> sriLankaGazetteer = [
    ResolvedLocation(
      displayName: 'Fort, Colombo 01, Sri Lanka',
      address: 'Fort, Colombo 01',
      city: 'Colombo 1',
      latitude: 6.9344,
      longitude: 79.8428,
    ),
    ResolvedLocation(
      displayName: 'Slave Island, Colombo 02, Sri Lanka',
      address: 'Slave Island, Colombo 02',
      city: 'Colombo 2',
      latitude: 6.9219,
      longitude: 79.8507,
    ),
    ResolvedLocation(
      displayName: 'Kollupitiya, Galle Road, Colombo 03',
      address: 'Kollupitiya, Galle Road',
      city: 'Colombo 3',
      latitude: 6.9022,
      longitude: 79.8530,
    ),
    ResolvedLocation(
      displayName: 'Bambalapitiya, Galle Road, Colombo 04',
      address: 'Bambalapitiya, Galle Road',
      city: 'Colombo 4',
      latitude: 6.8935,
      longitude: 79.8555,
    ),
    ResolvedLocation(
      displayName: 'Havelock Town, Colombo 05',
      address: 'Havelock Road',
      city: 'Colombo 5',
      latitude: 6.8842,
      longitude: 79.8665,
    ),
    ResolvedLocation(
      displayName: 'Wellawatte, Galle Road, Colombo 06',
      address: 'Wellawatte, Galle Road',
      city: 'Colombo 6',
      latitude: 6.8741,
      longitude: 79.8605,
    ),
    ResolvedLocation(
      displayName: 'Cinnamon Gardens, Independence Ave, Colombo 07',
      address: 'Independence Avenue, Cinnamon Gardens',
      city: 'Colombo 7',
      latitude: 6.9099,
      longitude: 79.8648,
    ),
    ResolvedLocation(
      displayName: 'Borella Junction, Colombo 08',
      address: 'Borella Junction, Ward Place',
      city: 'Colombo 8',
      latitude: 6.9147,
      longitude: 79.8778,
    ),
    ResolvedLocation(
      displayName: 'Dematagoda, Colombo 09',
      address: 'Baseline Road, Dematagoda',
      city: 'Colombo 9',
      latitude: 6.9288,
      longitude: 79.8789,
    ),
    ResolvedLocation(
      displayName: 'Maradana Road, Colombo 10',
      address: 'Maradana Road',
      city: 'Colombo 10',
      latitude: 6.9271,
      longitude: 79.8612,
    ),
    ResolvedLocation(
      displayName: 'Pettah Main Street, Colombo 11',
      address: 'Main Street, Pettah',
      city: 'Colombo 11',
      latitude: 6.9367,
      longitude: 79.8515,
    ),
    ResolvedLocation(
      displayName: 'Kotahena, Colombo 13',
      address: 'George R. De Silva Mawatha, Kotahena',
      city: 'Colombo 13',
      latitude: 6.9478,
      longitude: 79.8602,
    ),
    ResolvedLocation(
      displayName: 'Grandpass, Colombo 14',
      address: 'Grandpass Road',
      city: 'Colombo 14',
      latitude: 6.9475,
      longitude: 79.8732,
    ),
    ResolvedLocation(
      displayName: 'Dehiwala, Galle Road',
      address: 'Galle Road, Dehiwala',
      city: 'Dehiwala',
      latitude: 6.8511,
      longitude: 79.8654,
    ),
    ResolvedLocation(
      displayName: 'Mount Lavinia, Hotel Road',
      address: 'Hotel Road, Mount Lavinia',
      city: 'Mount Lavinia',
      latitude: 6.8301,
      longitude: 79.8633,
    ),
    ResolvedLocation(
      displayName: 'Moratuwa, Galle Road',
      address: 'Galle Road, Moratuwa',
      city: 'Moratuwa',
      latitude: 6.7730,
      longitude: 79.8816,
    ),
    ResolvedLocation(
      displayName: 'Nugegoda, High Level Road',
      address: 'High Level Road, Nugegoda',
      city: 'Nugegoda',
      latitude: 6.8649,
      longitude: 79.8997,
    ),
    ResolvedLocation(
      displayName: 'Maharagama, High Level Road',
      address: 'High Level Road, Maharagama',
      city: 'Maharagama',
      latitude: 6.8480,
      longitude: 79.9265,
    ),
    ResolvedLocation(
      displayName: 'Kottawa Junction, High Level Road',
      address: 'High Level Road, Kottawa',
      city: 'Kottawa',
      latitude: 6.8412,
      longitude: 79.9654,
    ),
    ResolvedLocation(
      displayName: 'Homagama Town, High Level Road',
      address: 'High Level Road, Homagama',
      city: 'Homagama',
      latitude: 6.8440,
      longitude: 80.0024,
    ),
    ResolvedLocation(
      displayName: 'Sri Jayawardenepura Kotte, Parliament Road',
      address: 'Parliament Road, Kotte',
      city: 'Kotte',
      latitude: 6.8905,
      longitude: 79.9018,
    ),
    ResolvedLocation(
      displayName: 'Rajagiriya, Sri Jayawardenepura Mawatha',
      address: 'Sri Jayawardenepura Mawatha, Rajagiriya',
      city: 'Rajagiriya',
      latitude: 6.9100,
      longitude: 79.8947,
    ),
    ResolvedLocation(
      displayName: 'Battaramulla, Denzil Kobbekaduwa Mawatha',
      address: 'Denzil Kobbekaduwa Mawatha, Battaramulla',
      city: 'Battaramulla',
      latitude: 6.8984,
      longitude: 79.9222,
    ),
    ResolvedLocation(
      displayName: 'Malabe, New Kandy Road',
      address: 'New Kandy Road, Malabe',
      city: 'Malabe',
      latitude: 6.9061,
      longitude: 79.9696,
    ),
    ResolvedLocation(
      displayName: 'Kelaniya, Kandy Road',
      address: 'Kandy Road, Kelaniya',
      city: 'Kelaniya',
      latitude: 6.9553,
      longitude: 79.9220,
    ),
    ResolvedLocation(
      displayName: 'Kiribathgoda, Kandy Road',
      address: 'Kandy Road, Kiribathgoda',
      city: 'Kiribathgoda',
      latitude: 6.9781,
      longitude: 79.9272,
    ),
    ResolvedLocation(
      displayName: 'Wattala, Negombo Road',
      address: 'Negombo Road, Wattala',
      city: 'Wattala',
      latitude: 6.9892,
      longitude: 79.8917,
    ),
    ResolvedLocation(
      displayName: 'Negombo, Main Street',
      address: 'Main Street, Negombo',
      city: 'Negombo',
      latitude: 7.2008,
      longitude: 79.8737,
    ),
    ResolvedLocation(
      displayName: 'Gampaha, Yakkala Road',
      address: 'Yakkala Road, Gampaha',
      city: 'Gampaha',
      latitude: 7.0873,
      longitude: 79.9990,
    ),
    ResolvedLocation(
      displayName: 'Panadura, Galle Road',
      address: 'Galle Road, Panadura',
      city: 'Panadura',
      latitude: 6.7132,
      longitude: 79.9026,
    ),
    ResolvedLocation(
      displayName: 'Kalutara, Galle Road',
      address: 'Galle Road, Kalutara',
      city: 'Kalutara',
      latitude: 6.5854,
      longitude: 79.9607,
    ),
    ResolvedLocation(
      displayName: 'Galle, Wakwella Road',
      address: 'Wakwella Road, Galle',
      city: 'Galle',
      latitude: 6.0329,
      longitude: 80.2168,
    ),
    ResolvedLocation(
      displayName: 'Matara, Anagarika Dharmapala Mawatha',
      address: 'Anagarika Dharmapala Mawatha, Matara',
      city: 'Matara',
      latitude: 5.9549,
      longitude: 80.5550,
    ),
    ResolvedLocation(
      displayName: 'Hambantota, Main Street',
      address: 'Main Street, Hambantota',
      city: 'Hambantota',
      latitude: 6.1246,
      longitude: 81.1185,
    ),
    ResolvedLocation(
      displayName: 'Kandy, Peradeniya Road',
      address: 'Peradeniya Road, Kandy',
      city: 'Kandy',
      latitude: 7.2906,
      longitude: 80.6337,
    ),
    ResolvedLocation(
      displayName: 'Peradeniya, Galaha Road',
      address: 'Galaha Road, Peradeniya',
      city: 'Peradeniya',
      latitude: 7.2631,
      longitude: 80.5928,
    ),
    ResolvedLocation(
      displayName: 'Matale, Trincomalee Street',
      address: 'Trincomalee Street, Matale',
      city: 'Matale',
      latitude: 7.4675,
      longitude: 80.6234,
    ),
    ResolvedLocation(
      displayName: 'Dambulla, Kandy-Jaffna Highway',
      address: 'Kandy-Jaffna Highway, Dambulla',
      city: 'Dambulla',
      latitude: 7.8742,
      longitude: 80.6511,
    ),
    ResolvedLocation(
      displayName: 'Nuwara Eliya, Badulla Road',
      address: 'Badulla Road, Nuwara Eliya',
      city: 'Nuwara Eliya',
      latitude: 6.9497,
      longitude: 80.7891,
    ),
    ResolvedLocation(
      displayName: 'Kurunegala, Colombo Road',
      address: 'Colombo Road, Kurunegala',
      city: 'Kurunegala',
      latitude: 7.4818,
      longitude: 80.3609,
    ),
    ResolvedLocation(
      displayName: 'Puttalam, Colombo Road',
      address: 'Colombo Road, Puttalam',
      city: 'Puttalam',
      latitude: 8.0362,
      longitude: 79.8283,
    ),
    ResolvedLocation(
      displayName: 'Chilaw, Colombo Road',
      address: 'Colombo Road, Chilaw',
      city: 'Chilaw',
      latitude: 7.5758,
      longitude: 79.7953,
    ),
    ResolvedLocation(
      displayName: 'Kegalle, Kandy Road',
      address: 'Kandy Road, Kegalle',
      city: 'Kegalle',
      latitude: 7.2513,
      longitude: 80.3464,
    ),
    ResolvedLocation(
      displayName: 'Ratnapura, Main Street',
      address: 'Main Street, Ratnapura',
      city: 'Ratnapura',
      latitude: 6.7056,
      longitude: 80.3847,
    ),
    ResolvedLocation(
      displayName: 'Badulla, Lower Street',
      address: 'Lower Street, Badulla',
      city: 'Badulla',
      latitude: 6.9934,
      longitude: 81.0550,
    ),
    ResolvedLocation(
      displayName: 'Bandarawela, Main Street',
      address: 'Main Street, Bandarawela',
      city: 'Bandarawela',
      latitude: 6.8304,
      longitude: 80.9889,
    ),
    ResolvedLocation(
      displayName: 'Anuradhapura, Maithripala Senanayake Mawatha',
      address: 'Maithripala Senanayake Mawatha, Anuradhapura',
      city: 'Anuradhapura',
      latitude: 8.3114,
      longitude: 80.4037,
    ),
    ResolvedLocation(
      displayName: 'Polonnaruwa, Hospital Junction',
      address: 'Hospital Junction, Polonnaruwa',
      city: 'Polonnaruwa',
      latitude: 7.9403,
      longitude: 81.0188,
    ),
    ResolvedLocation(
      displayName: 'Trincomalee, Dockyard Road',
      address: 'Dockyard Road, Trincomalee',
      city: 'Trincomalee',
      latitude: 8.5874,
      longitude: 81.2152,
    ),
    ResolvedLocation(
      displayName: 'Batticaloa, Trinco Road',
      address: 'Trinco Road, Batticaloa',
      city: 'Batticaloa',
      latitude: 7.7310,
      longitude: 81.6747,
    ),
    ResolvedLocation(
      displayName: 'Ampara, D.S. Senanayake Street',
      address: 'D.S. Senanayake Street, Ampara',
      city: 'Ampara',
      latitude: 7.2975,
      longitude: 81.6820,
    ),
    ResolvedLocation(
      displayName: 'Jaffna, Hospital Road',
      address: 'Hospital Road, Jaffna',
      city: 'Jaffna',
      latitude: 9.6615,
      longitude: 80.0255,
    ),
    ResolvedLocation(
      displayName: 'Kilinochchi, A9 Highway',
      address: 'A9 Highway, Kilinochchi',
      city: 'Kilinochchi',
      latitude: 9.3803,
      longitude: 80.3770,
    ),
    ResolvedLocation(
      displayName: 'Vavuniya, Kandy Road',
      address: 'Kandy Road, Vavuniya',
      city: 'Vavuniya',
      latitude: 8.7542,
      longitude: 80.4982,
    ),
    ResolvedLocation(
      displayName: 'Mannar, Main Street',
      address: 'Main Street, Mannar',
      city: 'Mannar',
      latitude: 8.9810,
      longitude: 79.9044,
    ),
  ];

  static List<ResolvedLocation> localSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return sriLankaGazetteer.take(8).toList();

    final scored = <(int, ResolvedLocation)>[];
    for (final entry in sriLankaGazetteer) {
      final cityL = entry.city.toLowerCase();
      final addrL = entry.address.toLowerCase();
      final dispL = entry.displayName.toLowerCase();
      int score;
      if (q == cityL) {
        score = 0;
      } else if (cityL.startsWith(q)) {
        score = 1;
      } else if (cityL.contains(q)) {
        score = 2;
      } else if (addrL.startsWith(q)) {
        score = 3;
      } else if (addrL.contains(q) || dispL.contains(q) || q.contains(cityL)) {
        score = 4;
      } else {
        continue;
      }
      final customAddress =
          (query.trim().length > entry.city.length && query.contains(','))
              ? query.trim()
              : entry.address;
      scored.add((
        score,
        ResolvedLocation(
          displayName: '$customAddress, ${entry.city}',
          address: customAddress,
          city: entry.city,
          latitude: entry.latitude,
          longitude: entry.longitude,
        ),
      ));
    }
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    return scored.map((e) => e.$2).toList();
  }

  static Future<List<ResolvedLocation>> searchAddressOrTown(
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return sriLankaGazetteer.take(8).toList();
    }

    final local = localSearch(trimmed);

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/issues/geocode')
          .replace(queryParameters: {'q': trimmed});
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final items = decoded['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          return items
              .map(
                (item) => ResolvedLocation.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        }
      }
    } catch (_) {}

    if (local.isNotEmpty) return local;

    // Fallback: match individual words against towns
    final words = trimmed
        .toLowerCase()
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3)
        .toList();
    for (final entry in sriLankaGazetteer) {
      final cityL = entry.city.toLowerCase();
      final addrL = entry.address.toLowerCase();
      if (words.any((w) => cityL.contains(w) || addrL.contains(w))) {
        return [
          ResolvedLocation(
            displayName: '$trimmed, ${entry.city}',
            address: trimmed,
            city: entry.city,
            latitude: entry.latitude,
            longitude: entry.longitude,
          ),
        ];
      }
    }

    return [
      ResolvedLocation(
        displayName: '$trimmed, Colombo',
        address: trimmed,
        city: trimmed.length <= 24 ? trimmed : 'Colombo',
        latitude: 6.9271,
        longitude: 79.8612,
      ),
    ];
  }

  static Future<ResolvedLocation> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final nearest = nearestGazetteerEntry(latitude, longitude);
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/issues/reverse-geocode')
          .replace(
        queryParameters: {
          'lat': latitude.toStringAsFixed(6),
          'lon': longitude.toStringAsFixed(6),
        },
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return ResolvedLocation.fromJson(decoded);
      }
    } catch (_) {}

    return ResolvedLocation(
      displayName: '${nearest.address}, ${nearest.city}',
      address: nearest.address,
      city: nearest.city,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static Future<ResolvedLocation> detectCurrentLocation() async {
    try {
      final res = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          return await reverseGeocode(lat, lon);
        }
      }
    } catch (_) {}
    return sriLankaGazetteer.first;
  }

  static ResolvedLocation nearestGazetteerEntry(
    double latitude,
    double longitude,
  ) {
    var best = sriLankaGazetteer.first;
    var bestDist = double.infinity;
    for (final entry in sriLankaGazetteer) {
      final d = math.sqrt(
        math.pow(entry.latitude - latitude, 2) +
            math.pow(entry.longitude - longitude, 2),
      );
      if (d < bestDist) {
        bestDist = d;
        best = entry;
      }
    }
    return best;
  }
}
