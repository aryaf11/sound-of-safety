class AuthSaveState {
  const AuthSaveState({
    required this.username,
    required this.email,
    required this.completedRegistration,
    required this.emailVerified,
  });

  final String username;
  final String email;
  final bool completedRegistration;
  final bool emailVerified;

  AuthSaveState copyWith({
    String? username,
    String? email,
    bool? completedRegistration,
    bool? emailVerified,
  }) {
    return AuthSaveState(
      username: username ?? this.username,
      email: email ?? this.email,
      completedRegistration:
          completedRegistration ?? this.completedRegistration,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
