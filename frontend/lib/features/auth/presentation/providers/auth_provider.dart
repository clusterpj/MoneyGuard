import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyguard/core/network/api_client.dart';
import 'package:moneyguard/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:moneyguard/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:moneyguard/features/auth/domain/entities/user.dart';
import 'package:moneyguard/features/auth/domain/repositories/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final authBoxProvider = Provider<Box>((ref) {
  return Hive.box('auth');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteDataSourceProvider),
    ref.read(authBoxProvider),
  );
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repository = ref.read(authRepositoryProvider);

    final apiClient = ref.read(apiClientProvider);
    final subscription = apiClient.authErrorStream.listen((_) {
      logout();
    });
    ref.onDispose(subscription.cancel);

    return await repository.getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.login(email, password);
    });
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.register(email, password, name, phone);
    });
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AsyncValue.data(null);
  }
}
