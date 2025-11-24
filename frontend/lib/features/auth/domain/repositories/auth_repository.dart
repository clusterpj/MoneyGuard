import 'package:moneyguard/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(
    String email,
    String password,
    String name,
    String phone,
  );
  Future<void> logout();
  Future<User?> getCurrentUser();
}
