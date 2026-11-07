import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_city_app/features/traffic/models/traffic_officer_model.dart';
import 'package:smart_city_app/features/traffic/services/traffic_service.dart';

void main() {
  final sample = <String, dynamic>{
    'id': 11, 'title': 'Traffic signal fault', 'description': 'Red light broken',
    'status': 'reported', 'priority': 'high',
    'department_id': 1, 'department_name': 'Traffic Department',
    'assigned_officer_id': 3, 'assigned_officer_name': 'Test Officer',
    'ai_recommended_priority': 'critical',
    'latest_priority_review': null,
    'departments': [{'id': 1, 'name': 'Traffic Department'}],
    'officers': [{'id': 3, 'name': 'Test Officer'}],
    'notes': [
      {'id': 2, 'comment': 'Investigating signal', 'visibility': 'internal',
       'author_name': 'Test Officer', 'created_at': '2026-11-05T14:00:00'}
    ],
  };

  test('Officer issue parses roles, departments and private notes', () {
    final item = TrafficOfficerIssue.fromJson(sample);
    expect(item.departmentName, 'Traffic Department');
    expect(item.officers.single.id, 3);
    expect(item.aiRecommendedPriority, 'critical');
    expect(item.notes.single.visibility, 'internal');
  });

  test('Officer API sends bearer token and department assignment to correct endpoint', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer local-test-token');
      if (request.method == 'GET') {
        expect(request.url.path, '/api/v1/traffic/officer/issues/11');
        return http.Response(jsonEncode(sample), 200);
      }
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/traffic/officer/issues/11/department');
      expect(jsonDecode(request.body)['department_id'], 1);
      return http.Response('{"message":"Department assigned"}', 200);
    });
    final service = TrafficService(client: client);
    service.setOfficerToken('local-test-token');
    expect((await service.getOfficerIssue(11)).assignedOfficerId, 3);
    await service.assignTrafficDepartment(11, 1);
    service.clearOfficerToken();
    expect(service.hasOfficerToken, isFalse);
    client.close();
  });

  test('No officer token blocks write before sending request', () async {
    var called = false;
    final service = TrafficService(client: MockClient((request) async {
      called = true;
      return http.Response('{}', 200);
    }));
    await expectLater(
      service.saveTrafficOfficerUpdate(11, status: 'resolved'),
      throwsA(isA<TrafficApiException>()),
    );
    expect(called, isFalse);
  });

  test('Officer status update includes public and internal updates', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.headers['Authorization'], 'Bearer secure-token');
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['status'], 'in_progress');
      expect(payload['internal_note'], 'Dispatch info');
      expect(payload['public_update'], 'Team is on the way');
      return http.Response('{"message":"Traffic issue updated","status":"in_progress"}', 200);
    });
    final service = TrafficService(client: client);
    service.setOfficerToken('secure-token');
    await service.saveTrafficOfficerUpdate(11, status: 'in_progress',
        internalNote: 'Dispatch info', publicUpdate: 'Team is on the way');
    client.close();
  });
}
