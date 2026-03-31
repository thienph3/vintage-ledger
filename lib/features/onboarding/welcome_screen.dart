import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/locale_toggle.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/onboarding/sample_data_service.dart';
import 'package:vintage_ledger/features/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loading = false;

  Future<void> _start({required bool withSample}) async {
    setState(() => _loading = true);

    if (withSample) {
      await SampleDataService().generate();
    }

    await sl.settingService.markSetupDone();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Locale toggle
              const Align(
                alignment: Alignment.topRight,
                child: LocaleToggle(),
              ),

              const Spacer(),

              // Icon
              Icon(Icons.menu_book_rounded, size: 80, color: AppColors.inkBlue),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                S.of(context, 'welcomeTitle'),
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Subtitle
              Text(
                S.of(context, 'welcomeSubtitle'),
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              if (_loading)
                const CircularProgressIndicator()
              else ...[
                // With sample data
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _start(withSample: true),
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: Text(S.of(context, 'startWithSample')),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Without sample data
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _start(withSample: false),
                    child: Text(S.of(context, 'startEmpty')),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
