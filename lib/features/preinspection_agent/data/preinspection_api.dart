import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/services/api_client.dart';
import '../domain/models/claim.dart';
import '../domain/models/owner_vehicle_details.dart';

/// The signed-in field user, as the server returns it.
class AppUser {
  const AppUser({
    required this.id,
    required this.userId,
    required this.name,
    required this.role,
    required this.roleName,
    required this.organization,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String,
    userId: j['userId'] as String,
    name: j['name'] as String,
    role: j['role'] as String,
    roleName: (j['roleName'] ?? '') as String,
    organization: (j['organization'] ?? '') as String,
  );

  final String id;
  final String userId;
  final String name;

  /// 'agent' | 'surveyor' (the login tab).
  final String role;
  final String roleName;
  final String organization;
}

/// Result of an upload: the server's media id.
class UploadedMedia {
  const UploadedMedia(this.id, this.url);
  final String id;
  final String url;
}

String mimeForPath(String path) => switch (p.extension(path).toLowerCase()) {
  '.png' => 'image/png',
  '.webp' => 'image/webp',
  '.heic' => 'image/heic',
  '.mp4' => 'video/mp4',
  '.mov' => 'video/quicktime',
  '.3gp' => 'video/3gpp',
  '.webm' => 'video/webm',
  '.pdf' => 'application/pdf',
  _ => 'image/jpeg',
};

/// Calls of the Pre-Inspection Agent app (admin-service `/api/v1/field/...`).
class PreinspectionApi {
  PreinspectionApi(this.client);

  final ApiClient client;

  Future<(String token, AppUser user)> login({
    required String userId,
    required String password,
    required String role,
  }) async {
    final data =
        await client.post('/field/auth/login', {
              'userId': userId,
              'password': password,
              'role': role,
            })
            as Map<String, dynamic>;
    return (
      data['token'] as String,
      AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await client.post('/field/auth/logout');
    } catch (_) {
      // Signing out locally is what matters.
    }
  }

  Future<List<Claim>> listInspections() async {
    final data = await client.get('/field/inspections') as List<dynamic>;
    return data.map((e) => Claim.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Full record incl. `details` (owner & vehicle form) and `media`.
  Future<Map<String, dynamic>> getInspection(String id) async =>
      await client.get('/field/inspections/${Uri.encodeComponent(id)}')
          as Map<String, dynamic>;

  static Map<String, dynamic> ownerJson(OwnerVehicleDetails d) => {
    'surveyType': d.surveyType,
    'ownerName': d.ownerName,
    'mobile': d.mobile,
    'email': d.email,
    'odometer': d.odometer,
    'registrationNumber': d.registrationNumber,
    'state': d.state,
    'registrationDate': d.registrationDate,
    'product': d.product,
    'make': d.make,
    'model': d.model,
    'variant': d.variant,
    'manufacturingYear': d.manufacturingYear,
    'ownerSerialNumber': d.ownerSerialNumber,
    'idv': d.idv,
  };

  /// Starts a new pre-inspection (when the agent was not assigned one).
  Future<Map<String, dynamic>> createInspection(OwnerVehicleDetails d) async =>
      await client.post('/field/inspections', ownerJson(d))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateInspection(
    String id,
    Map<String, dynamic> fields,
  ) async =>
      await client.patch(
            '/field/inspections/${Uri.encodeComponent(id)}',
            fields,
          )
          as Map<String, dynamic>;

  /// Uploads one file into (kind, slot); re-uploading a slot replaces it.
  Future<UploadedMedia> uploadFile(
    String inspectionId,
    String kind,
    String slot,
    String path, {
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
  }) async {
    final data =
        await client.putFile(
              '/field/inspections/${Uri.encodeComponent(inspectionId)}/media/$kind/${Uri.encodeComponent(slot)}',
              File(path),
              mimeForPath(path),
              query: {
                if (latitude != null) 'lat': '$latitude',
                if (longitude != null) 'lng': '$longitude',
                if (capturedAt != null)
                  'capturedAt': capturedAt.toUtc().toIso8601String(),
              },
            )
            as Map<String, dynamic>;
    return UploadedMedia(data['id'] as String, data['url'] as String);
  }

  Future<UploadedMedia> uploadPng(
    String inspectionId,
    String kind,
    String slot,
    Uint8List bytes,
  ) async {
    final data =
        await client.putBytes(
              '/field/inspections/${Uri.encodeComponent(inspectionId)}/media/$kind/${Uri.encodeComponent(slot)}',
              bytes,
              'image/png',
            )
            as Map<String, dynamic>;
    return UploadedMedia(data['id'] as String, data['url'] as String);
  }

  Future<void> deleteMedia(
    String inspectionId,
    String mediaId,
  ) => client.delete(
    '/field/inspections/${Uri.encodeComponent(inspectionId)}/media/${Uri.encodeComponent(mediaId)}',
  );

  Future<Map<String, dynamic>> submit(String inspectionId) async =>
      await client.post(
            '/field/inspections/${Uri.encodeComponent(inspectionId)}/submit',
          )
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> submitRepair(String inspectionId) async =>
      await client.post(
            '/field/inspections/${Uri.encodeComponent(inspectionId)}/repair-submit',
          )
          as Map<String, dynamic>;
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final preinspectionApiProvider = Provider<PreinspectionApi>(
  (ref) => PreinspectionApi(ref.watch(apiClientProvider)),
);
