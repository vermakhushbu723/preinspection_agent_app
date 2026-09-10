import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which kind of user is signed in. The preinspection portal is used both by
/// field agents and by surveyors, and the screens after login need to say
/// whose id they are working under — so the role is picked on the login form
/// rather than assumed.
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
}

/// The signed-in user: the id typed on the login form and the role its tab
/// selected. Held in memory only — login is required on every app start, so
/// there is nothing here worth persisting.
class Session {
  const Session({required this.userId, required this.role});

  final String userId;
  final UserRole role;
}

class SessionNotifier extends StateNotifier<Session?> {
  SessionNotifier() : super(null);

  void signIn({required String userId, required UserRole role}) =>
      state = Session(userId: userId, role: role);

  void signOut() => state = null;
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Session?>(
  (ref) => SessionNotifier(),
);
