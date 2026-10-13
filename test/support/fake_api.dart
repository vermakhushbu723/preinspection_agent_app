import 'dart:typed_data';

import 'package:preinspection_agent_app/core/services/api_client.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/data/preinspection_api.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/models/claim.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/models/owner_vehicle_details.dart';

/// In-memory stand-in for admin-service's field API, recording every call.
class FakePreinspectionApi extends PreinspectionApi {
  FakePreinspectionApi() : super(ApiClient(baseUrl: 'http://fake.invalid'));

  final List<String> calls = [];
  final Map<String, Map<String, dynamic>> patches = {};
  final List<String> uploaded = [];

  /// Make the next N uploads fail (simulates being offline).
  int failUploads = 0;
  String? loginError;
  List<Claim> inspections = const [];
  int _media = 0;

  @override
  Future<(String, AppUser)> login({
    required String userId,
    required String password,
    required String role,
  }) async {
    calls.add('login $userId $role');
    if (loginError != null) throw ApiException(loginError!, status: 401);
    return (
      'token-123',
      AppUser(
        id: 'USR-1001',
        userId: userId,
        name: 'Test $role',
        role: role,
        roleName: role == 'agent'
            ? 'Pre-Inspection Agent'
            : 'Pre-Inspection Surveyor',
        organization: 'ABG Insurance',
      ),
    );
  }

  @override
  Future<void> logout() async => calls.add('logout');

  @override
  Future<List<Claim>> listInspections() async {
    calls.add('list');
    return inspections;
  }

  @override
  Future<Map<String, dynamic>> getInspection(String id) async {
    calls.add('get $id');
    return {
      'id': id,
      'inspectionStatus': 'Assigned',
      'workflow': null,
      'details': {
        'ownerName': 'Asha Mehta',
        'mobile': '9811100000',
        'registrationNumber': 'GJ01AA1111',
        'surveyType': 'pre inspection',
      },
      'media': [
        {'id': 'm-1', 'kind': 'document', 'slot': 'rc_front'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> createInspection(OwnerVehicleDetails d) async {
    calls.add('create ${d.registrationNumber}');
    return {'id': 'PI-100001', 'inspectionStatus': 'Draft'};
  }

  @override
  Future<Map<String, dynamic>> updateInspection(
    String id,
    Map<String, dynamic> fields,
  ) async {
    calls.add('patch $id');
    patches[id] = {...?patches[id], ...fields};
    return {'id': id, 'inspectionStatus': 'Draft'};
  }

  @override
  Future<UploadedMedia> uploadFile(
    String inspectionId,
    String kind,
    String slot,
    String path, {
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
  }) async {
    if (failUploads > 0) {
      failUploads--;
      throw const ApiException('No internet connection.');
    }
    uploaded.add('$kind/$slot');
    _media++;
    return UploadedMedia('m$_media', '/media/$_media');
  }

  @override
  Future<UploadedMedia> uploadPng(
    String inspectionId,
    String kind,
    String slot,
    Uint8List bytes,
  ) async {
    uploaded.add('$kind/$slot');
    _media++;
    return UploadedMedia('m$_media', '/media/$_media');
  }

  @override
  Future<void> deleteMedia(String inspectionId, String mediaId) async =>
      calls.add('delete $mediaId');

  @override
  Future<Map<String, dynamic>> submit(String inspectionId) async {
    calls.add('submit $inspectionId');
    return {'id': inspectionId, 'inspectionStatus': 'Submitted'};
  }

  @override
  Future<Map<String, dynamic>> submitRepair(String inspectionId) async {
    calls.add('repair $inspectionId');
    return {'id': inspectionId, 'inspectionStatus': 'Submitted'};
  }
}
