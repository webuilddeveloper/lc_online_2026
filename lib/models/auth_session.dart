import 'package:LawyerOnline/models/user_model.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
  });

  final UserModel user;
  final String token;
}
