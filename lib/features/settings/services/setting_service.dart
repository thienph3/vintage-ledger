import 'package:vintage_ledger/features/settings/repositories/setting_repository.dart';

class SettingService {
  final SettingRepository _repo = SettingRepository();

  static const _localeKey = 'locale';

  Future<String> getLocale() async {
    return await _repo.get(_localeKey) ?? 'vi';
  }

  Future<void> setLocale(String locale) async {
    await _repo.set(_localeKey, locale);
  }
}
