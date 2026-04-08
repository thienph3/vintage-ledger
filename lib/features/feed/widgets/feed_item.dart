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
  final String? boldPrefix;
  final String? textAfterPrefix;

  const FeedItem({
    super.key,
    required this.actorName,
    required this.text,
    required this.time,
    this.photoUrl,
    this.onTap,
    this.isSystemMessage = false,
    this.boldPrefix,
    this.textAfterPrefix,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
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
                  boldPrefix != null
                      ? RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: boldPrefix,
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: textAfterPrefix ?? '',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        )
                      : Text(text, style: AppTextStyles.body),
                  const SizedBox(height: AppSpacing.xs),
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
