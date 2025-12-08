import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyguard/features/auth/presentation/providers/auth_provider.dart';
import 'package:moneyguard/features/ai_advisor/data/datasources/ai_remote_data_source.dart';
import 'package:moneyguard/features/ai_advisor/data/repositories/ai_repository_impl.dart';
import 'package:moneyguard/features/ai_advisor/domain/repositories/ai_repository.dart';

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(ref.read(aiRemoteDataSourceProvider));
});

class AiChatState {
  final List<ApiMessage> messages;
  final bool isLoading;
  final String? error;

  AiChatState({required this.messages, this.isLoading = false, this.error});

  AiChatState copyWith({
    List<ApiMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ApiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ApiMessage({required this.text, required this.isUser})
    : timestamp = DateTime.now();
}

class AiChatNotifier extends Notifier<AiChatState> {
  late final AiRepository _repository;

  @override
  AiChatState build() {
    _repository = ref.read(aiRepositoryProvider);
    return AiChatState(messages: []);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ApiMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _repository.sendMessage(text);
      final aiMessage = ApiMessage(text: response, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);
