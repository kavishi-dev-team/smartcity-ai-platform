import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_city_app/features/traffic/models/department_model.dart';
import 'package:smart_city_app/features/traffic/services/traffic_service.dart';

void main() {
  const sample = <String, dynamic>{
    'id': 2,
    'name': 'Traffic Control',
    'description': 'Manages signals',
    'responsibilities': 'Signal maintenance',
    'contact_email': null,
    'contact_phone': null,
    'office_address': null,
    'office_city': 'Galle',
    'office_latitude': 6.05,
    'office_longitude': 80.22,
    'operating_hours': 'Mon-Fri 08:00-16:00',
    'traffic_issue_count': 2,
  };

  test('Department model parses nullable contact and location fields', () {
    final dept = DepartmentInfo.fromJson(sample);
    expect(dept.name, 'Traffic Control');
    expect(dept.contactPhone, isNull);
    expect(dept.responsibilities, 'Signal maintenance');
    expect(dept.hasValidCoordinates, isTrue);
    expect(dept.trafficIssueCount, 2);
  });

  test('Department list service sends search and offset', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/departments');
      expect(request.url.queryParameters['search'], 'traffic');
      expect(request.url.queryParameters['offset'], '1');
      return http.Response(jsonEncode({
        'items': [sample], 'total': 1, 'limit': 20, 'offset': 1,
      }), 200);
    });
    final service = TrafficService(client: client);
    final page = await service.getDepartments(search: 'traffic', offset: 1);
    expect(page.items.single.id, 2);
    service.dispose();
    client.close();
  });

  test('Department details fetch uses correct route', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/departments/2');
      return http.Response(jsonEncode(sample), 200);
    });
    final service = TrafficService(client: client);
    final dept = await service.getDepartment(2);
    expect(dept.operatingHours, 'Mon-Fri 08:00-16:00');
    client.close();
  });

  test('Department reports fetch parses traffic issue page', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/departments/2/issues');
      expect(request.url.queryParameters['limit'], '10');
      return http.Response(jsonEncode({
        'items': [], 'total': 0, 'limit': 10, 'offset': 0,
      }), 200);
    });
    final service = TrafficService(client: client);
    final page = await service.getDepartmentIssues(2);
    expect(page.total, 0);
    expect(page.items, isEmpty);
    client.close();
  });

  test('Missing office coordinates do not display a map', () {
    final dept = DepartmentInfo.fromJson({...sample, 'office_latitude': null});
    expect(dept.hasValidCoordinates, isFalse);
  });
}
