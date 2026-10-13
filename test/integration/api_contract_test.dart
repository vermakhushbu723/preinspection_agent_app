// Contract test: the app's real ApiClient + PreinspectionApi against a running
// admin-service. Skipped unless a backend is given:
//
//   flutter test test/integration/api_contract_test.dart \
//     --dart-define=CONTRACT_API=http://127.0.0.1:8040/api/v1 \
//     --dart-define=CONTRACT_ADMIN_PASSWORD=Admin@12345
//
// It creates its own agent through the admin API, so run it against a local
// / throwaway database only.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preinspection_agent_app/core/services/api_client.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/data/preinspection_api.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/models/owner_vehicle_details.dart';

const _api = String.fromEnvironment('CONTRACT_API');
const _adminPassword = String.fromEnvironment('CONTRACT_ADMIN_PASSWORD');

// 1x1 PNG.
final _png = Uint8List.fromList(const [
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13, //
  73,
  68,
  65,
  84,
  120,
  218,
  99,
  100,
  248,
  207,
  80,
  15,
  0,
  3,
  134,
  1,
  128,
  90,
  52,
  125,
  107,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

void main() {
  // No TestWidgetsFlutterBinding: it would replace HttpClient with a mock.
  final skip = _api.isEmpty ? 'set --dart-define=CONTRACT_API to run' : null;

  test('agent app flow against admin-service', () async {
    final admin = ApiClient(baseUrl: _api);
    final login =
        await admin.post('/auth/login', {
              'identifier': 'admin@ibima.com',
              'password': _adminPassword,
            })
            as Map;
    admin.token = login['token'] as String;

    final stamp = DateTime.now().millisecondsSinceEpoch % 100000000;
    final userId = 'contract.$stamp';
    await admin.post('/users', {
      'accountType': 'Internal',
      'roleKey': 'preinspection-agent',
      'reportingManagerId': 'ADMIN',
      'name': 'Contract Agent',
      'employeeId': 'EMP-C$stamp',
      'email': 'c$stamp@test.in',
      'contact': '97${stamp.toString().padLeft(8, '0')}',
      'platform': 'mobile',
      'status': 'Active',
      'userId': userId,
      'tempPassword': 'Agent@1234',
    });

    final app = PreinspectionApi(ApiClient(baseUrl: _api));
    // Wrong tab is refused with a readable reason.
    await expectLater(
      app.login(userId: userId, password: 'Agent@1234', role: 'surveyor'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
    );
    final (token, user) = await app.login(
      userId: userId,
      password: 'Agent@1234',
      role: 'agent',
    );
    app.client.token = token;
    expect(user.roleName, 'Pre-Inspection Agent');

    final created = await app.createInspection(
      const OwnerVehicleDetails(
        surveyType: 'pre inspection',
        ownerName: 'Contract Owner',
        mobile: '9876500000',
        email: 'owner@test.in',
        odometer: '1200',
        registrationNumber: 'MH12CT0001',
        state: 'Maharashtra',
        registrationDate: '01-02-2020',
        product: 'Private Car',
        make: 'Maruti Suzuki',
        model: 'Swift',
        variant: 'VXI',
        manufacturingYear: '01-2020',
        ownerSerialNumber: '1',
        idv: '',
      ),
    );
    final id = created['id'] as String;
    expect(created['inspectionStatus'], 'Draft');

    final dir = await Directory.systemTemp.createTemp('contract');
    final photo = File('${dir.path}/front.png')..writeAsBytesSync(_png);
    final media = await app.uploadFile(
      id,
      'photo',
      'front-side',
      photo.path,
      latitude: 19.07,
      longitude: 72.87,
      capturedAt: DateTime.now(),
    );
    expect(media.url, contains('sig='));
    await app.uploadPng(id, 'signature', 'customer', _png);
    await app.uploadPng(id, 'signature', 'inspector', _png);
    await app.updateInspection(id, {
      'workflow': 'others',
      'customerDeclaration': true,
      'inspectorDeclaration': true,
      'agentRecommendation': 'Approved',
    });
    final submitted = await app.submit(id);
    expect(submitted['inspectionStatus'], 'Submitted');

    final list = await app.listInspections();
    expect(list.firstWhere((c) => c.id == id).status, 'Completed');

    // ...and the Admin panel sees it with its files.
    final detail = await admin.get('/preinspections/$id') as Map;
    expect((detail['media'] as List).length, 3);
    expect(detail['agentUserId'], userId);
    await dir.delete(recursive: true);
  }, skip: skip);
}
