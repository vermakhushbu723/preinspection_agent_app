import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preinspection_api.dart';

/// Which kind of user is signed in. The preinspection portal is used both by
/// field agents and by surveyors, and the screens after login need to say
/// whose id they are working under — so the role is picked on the login form
/// rather than assumed. The server checks the account really has that role.
enum UserRole { agent, surveyor }

extension UserRoleX on UserRole {
  /// Tab caption on the login screen.
  String get shortLabel => switch (this) {
    UserRole.agent => 'Agent',
    UserRole.surveyor => 'Surveyor',
  };

  /// Full title shown once signed in.
  String get displayName => switch (this) {
    UserRole.agent => 'Pre-Inspection Agent',
    UserRole.surveyor => 'Pre-Inspection Surveyor',
  };

  /// Value the login API expects.
  String get apiValue => name;
}

/// The signed-in user (an account created in the IBima Assist Admin panel)
/// and their API token. Held in memory only — login is required on every
/// app start.
class Session {
  const Session({required this.user, required this.role, required this.token});

  final AppUser user;
  final UserRole role;
  final String token;

  /// The id typed on the login form, as stored on the server.
  String get userId => user.userId;
}

class SessionNotifier extends StateNotifier<Session?> {
  SessionNotifier(this._api) : super(null) {
    // Server says the token is no longer valid (expired, account suspended).
    _api.client.onUnauthorized = signOut;
  }

  final PreinspectionApi _api;

  /// Checks the credentials with the server; throws ApiException with a readable reason.
  Future<void> signIn({
    required String userId,
    required String password,
    required UserRole role,
  }) async {
    final (token, user) = await _api.login(
      userId: userId,
      password: password,
      role: role.apiValue,
    );
    _api.client.token = token;
    state = Session(user: user, role: role, token: token);
  }

  Future<void> logout() async {
    if (state != null) await _api.logout();
    signOut();
  }

  void signOut() {
    _api.client.token = null;
    state = null;
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Session?>(
  (ref) => SessionNotifier(ref.watch(preinspectionApiProvider)),
);
