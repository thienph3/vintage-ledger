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
                  _buildStoryText(),
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

  Widget _buildStoryText() {
    if (boldPrefix == null) {
      return Text(text, style: AppTextStyles.body);
    }

    // Render as a single flowing sentence.
    // Member name uses primary color to stand out reliably on all devices,
    // instead of relying on fontWeight which can be inconsistent.
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Text(
              boldPrefix!,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
          ),
          TextSpan(
            text: textAfterPrefix ?? '',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
