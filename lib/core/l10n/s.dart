import 'package:flutter/widgets.dart';
import 'app_vi.dart' as vi;
import 'app_en.dart' as en;

class S {
  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': vi.vi,
    'en': en.en,
  };

  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _localizedValues[locale]?[key] ??
        _localizedValues['vi']![key] ??
        key;
  }
}
