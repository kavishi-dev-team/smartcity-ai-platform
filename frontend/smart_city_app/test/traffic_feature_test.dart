import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:smart_city_app/features/traffic/widgets/traffic_photo_viewer.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_city_app/features/traffic/models/traffic_issue_model.dart';
import 'package:smart_city_app/features/traffic/services/traffic_service.dart';

void main() {
  const sample = <String, dynamic>{
    'id': 3,
    'title': 'Traffic signal not working',
    'description': 'Signal near the market is broken',
    'category': 'traffic',
    'status': 'reported',
    'priority': 'high',
    'department_id': null,
    'department_name': null,
    'location': {'latitude': 6.05, 'longitude': 80.2, 'city': 'Galle', 'address': 'Main Road'},
    'created_at': '2026-10-20T09:00:00',
    'updated_at': '2026-10-20T09:00:00',
  };

  test('Traffic issue parses location and priority', () {
    final issue = TrafficIssue.fromJson(sample);
    expect(issue.title, 'Traffic signal not working');
    expect(issue.location?.city, 'Galle');
    expect(issue.priority, 'high');
  });

  test('Traffic service sends search and filter parameters', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/issues');
      expect(request.url.queryParameters['category'], 'traffic');
      expect(request.url.queryParameters['search'], 'signal');
      expect(request.url.queryParameters['priority'], 'high');
      return http.Response(jsonEncode({
        'items': [sample], 'total': 1, 'limit': 20, 'offset': 0,
      }), 200, headers: {'content-type': 'application/json'});
    });
    final service = TrafficService(client: client, baseUrl: 'http://localhost:8000/api/v1');
    final result = await service.getIssues(search: 'signal', priority: 'high');
    expect(result.total, 1);
    expect(result.items.single.id, 3);
    client.close();
  });

  test('Traffic details parse photos and status history', () async {
    final client = MockClient((request) async => http.Response(jsonEncode({
      ...sample,
      'photos': [{'id': 2, 'file_name': 'photo.jpg', 'file_url': 'https://example.com/photo.jpg'}],
      'status_history': [{'previous_status': null, 'new_status': 'reported', 'note': 'Received', 'created_at': '2026-10-20T09:00:00'}],
      'ai_summary': 'Likely signal malfunction.',
      'similar_issues': [],
    }), 200));
    final service = TrafficService(client: client, baseUrl: 'http://localhost:8000/api/v1');
    final result = await service.getIssue(3);
    expect(result.photos.single.fileName, 'photo.jpg');
    expect(result.statusHistory.single.newStatus, 'reported');
    expect(result.aiSummary, contains('malfunction'));
    client.close();
  });

  test('Traffic map search sends a URL encoded location search term', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/traffic/map');
      expect(request.url.queryParameters['search'], 'Galle Main Road');
      return http.Response(jsonEncode({
        'items': [
          {'id': 3, 'title': 'Signal issue', 'status': 'reported',
           'priority': 'high', 'location': {
             'latitude': 6.05, 'longitude': 80.22,
             'address': 'Galle Main Road', 'city': 'Galle'}}
        ],
        'total': 1, 'limit': 500,
      }), 200);
    });
    final service = TrafficService(client: client);
    final result = await service.getMapMarkers(search: 'Galle Main Road');
    expect(result.total, 1);
    expect(result.items.single.location.city, 'Galle');
    expect(result.items.single.id, 3);
    client.close();
  });

  test('Location validity rejects out-of-range coordinates', () {
    final valid = TrafficLocation.fromJson({
      'latitude': 6.05, 'longitude': 80.22,
    });
    expect(valid.hasValidCoordinates, isTrue);
    const invalid = TrafficLocation(latitude: 101, longitude: 80);
    expect(invalid.hasValidCoordinates, isFalse);
  });


  testWidgets('Photo viewer supports multiple photos and a close action', (tester) async {
    const photos = [
      TrafficPhoto(id: 1, fileName: 'first.jpg', fileUrl: 'invalid-local-url'),
      TrafficPhoto(id: 2, fileName: 'second.jpg', fileUrl: 'invalid-local-url'),
    ];
    await tester.pumpWidget(const MaterialApp(
      home: TrafficPhotoViewer(photos: photos),
    ));
    expect(find.text('Photo 1 of 2'), findsOneWidget);
    expect(find.text('Photo URL is not available.'), findsWidgets);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Photo 2 of 2'), findsOneWidget);
    expect(find.byTooltip('Close photo viewer'), findsOneWidget);
  });

}
