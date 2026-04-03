import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class FeedItem extends StatelessWidget {
  final String actorName;
  final String text;
  final String time;
  final String? photoUrl;
  final VoidCallback? onTap;
  final bool isSystemMessage;

  const FeedItem({
    super.key,
    required this.actorName,
    required this.text,
    required this.time,
    this.photoUrl,
    this.onTap,
    this.isSystemMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Center(
          child: Text(text, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ),
      );
    }

    final initials = actorName.isNotEmpty ? actorName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Text(initials, style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14,
                    ))
                  : null,
            ),
            const SizedBox(width: AppSpacing.md2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: AppTextStyles.body),
                  const SizedBox(height: 2),
                  Text(time, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
