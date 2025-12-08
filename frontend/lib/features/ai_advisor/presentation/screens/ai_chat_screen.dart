import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/features/ai_advisor/presentation/providers/ai_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);

    // Auto-scroll when messages change
    ref.listen(aiChatProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentStart.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.accentStart,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MoneyGuard AI', style: AppTypography.titleMedium),
                Text(
                  'Financial Coach',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        state.messages.length + (state.isLoading ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const _ThinkingIndicator();
                      }
                      final message = state.messages[index];
                      return _MessageBubble(message: message);
                    },
                  ),
          ),
          if (state.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.error.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: AppColors.accentStart.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'How can I help you today?',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _SuggestionChip(
                label: '📊 Analyze my Spending',
                onTap: () => ref
                    .read(aiChatProvider.notifier)
                    .sendMessage('Analyze my spending habits for this month.'),
              ),
              _SuggestionChip(
                label: '🔮 Forecast next month',
                onTap: () => ref
                    .read(aiChatProvider.notifier)
                    .sendMessage(
                      'Forecast my spending for next month based on current trends.',
                    ),
              ),
              _SuggestionChip(
                label: '💸 Vacation Budget?',
                onTap: () => ref
                    .read(aiChatProvider.notifier)
                    .sendMessage('Can I afford a \$500 vacation next week?'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask about your finances...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.backgroundPrimary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (val) {
                ref.read(aiChatProvider.notifier).sendMessage(val);
                _controller.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                ref.read(aiChatProvider.notifier).sendMessage(_controller.text);
                _controller.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ApiMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser
        ? AppColors.primary.withOpacity(0.1)
        : AppColors.backgroundSecondary;
    final textColor = AppColors.textPrimary;

    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accentStart,
                child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: AppColors.backgroundTertiary),
                ),
                child: isUser
                    ? Text(message.text, style: TextStyle(color: textColor))
                    : MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: textColor),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentStart,
                          ),
                        ),
                      ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.textSecondary,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Text(
        'Thinking...',
        style: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.backgroundSecondary,
      side: const BorderSide(color: AppColors.accentStart),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
    );
  }
}
