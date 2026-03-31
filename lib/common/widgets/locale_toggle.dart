import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/main.dart';

class LocaleToggle extends StatelessWidget {
  const LocaleToggle({super.key});

  Future<void> _toggle(BuildContext context) async {
    final current = Localizations.localeOf(context).languageCode;
    final next = current == 'vi' ? 'en' : 'vi';
    await sl.settingService.setLocale(next);
    if (!context.mounted) return;
    MyApp.setLocale(context, Locale(next));
  }

  @override
  Widget build(BuildContext context) {
    final flag =
        Localizations.localeOf(context).languageCode == 'vi' ? '🇻🇳' : '🇺🇸';
    return GestureDetector(
      onTap: () => _toggle(context),
      child: Text(flag, style: AppTextStyles.emojiLarge),
    );
  }
}
