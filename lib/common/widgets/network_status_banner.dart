import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('__connectivity__')
          .doc('ping')
          .snapshots(includeMetadataChanges: true),
      builder: (context, snap) {
        final isOffline = snap.hasData && snap.data!.metadata.isFromCache;
        if (!isOffline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          color: AppColors.accent.withValues(alpha: 0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                S.of(context, 'offline'),
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        );
      },
    );
  }
}
