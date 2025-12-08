import 'package:flutter/material.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';

class SelectableChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAmount;

  const SelectableChip({
    super.key,
    required this.label,
    this.emoji,
    required this.isSelected,
    required this.onTap,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentStart.withOpacity(0.1)
              : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentStart : Colors.transparent,
            width: 1.5,
          ),
          gradient: isSelected && isAmount
              ? const LinearGradient(
                  colors: [AppColors.accentStart, AppColors.accentEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
            ],
            Text(
              label,
              style: isAmount && isSelected
                  ? AppTypography.labelLarge.copyWith(color: Colors.white)
                  : isSelected
                  ? AppTypography.labelLarge.copyWith(
                      color: AppColors.accentStart,
                    )
                  : AppTypography.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
