import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/settings/services/setting_service.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_header.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/main.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final SettingService _settingService = SettingService();
  String _currentLocale = 'vi';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final locale = await _settingService.getLocale();
    setState(() => _currentLocale = locale);
  }

  Future<void> _changeLocale(String locale) async {
    await _settingService.setLocale(locale);
    setState(() => _currentLocale = locale);
    MyApp.setLocale(context, Locale(locale));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "",
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LedgerHeader(
            title: S.of(context, 'settings'),
            showBackButton: true,
          ),
          const SizedBox(height: 16),
          Text(S.of(context, 'language'), style: AppTextStyles.title),
          const SizedBox(height: 8),
          _buildLanguageTile('vi', S.of(context, 'vietnamese'), '🇻🇳'),
          _buildLanguageTile('en', S.of(context, 'english'), '🇺🇸'),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(String locale, String label, String flag) {
    final isSelected = _currentLocale == locale;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: AppTextStyles.body),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.inkBlue)
          : null,
      onTap: () => _changeLocale(locale),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? AppColors.inkBlue.withValues(alpha: 0.1) : null,
    );
  }
}
