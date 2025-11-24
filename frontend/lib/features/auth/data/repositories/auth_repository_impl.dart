import 'package:moneyguard/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:moneyguard/features/auth/domain/entities/user.dart';
import 'package:moneyguard/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final Box _authBox;

  AuthRepositoryImpl(this._remoteDataSource, this._authBox);

  @override
  Future<User> login(String email, String password) async {
    final user = await _remoteDataSource.login(email, password);
    await _saveUser(user);
    return user;
  }

  @override
  Future<User> register(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    final user = await _remoteDataSource.register(email, password, name, phone);
    await _saveUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    await _authBox.clear();
  }

  @override
  Future<User?> getCurrentUser() async {
    final id = _authBox.get('id');
    final email = _authBox.get('email');
    final name = _authBox.get('name');
    final accessToken = _authBox.get('access_token');
    final refreshToken = _authBox.get('refresh_token');

    if (accessToken != null) {
      return User(
        id: id,
        email: email,
        name: name,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    return null;
  }

  Future<void> _saveUser(User user) async {
    await _authBox.put('id', user.id);
    await _authBox.put('email', user.email);
    await _authBox.put('name', user.name);
    if (user.accessToken != null) {
      await _authBox.put('access_token', user.accessToken);
    }
    if (user.refreshToken != null) {
      await _authBox.put('refresh_token', user.refreshToken);
    }
  }
}
