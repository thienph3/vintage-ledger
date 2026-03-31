import 'package:vintage_ledger/features/settings/repositories/setting_repository.dart';

class SettingService {
  final SettingRepository _repo = SettingRepository();

  static const _localeKey = 'locale';
  static const _setupDoneKey = 'setup_done';

  Future<String> getLocale() async {
    return await _repo.get(_localeKey) ?? 'vi';
  }

  Future<void> setLocale(String locale) async {
    await _repo.set(_localeKey, locale);
  }

  Future<bool> isSetupDone() async {
    return await _repo.get(_setupDoneKey) == 'true';
  }

  Future<void> markSetupDone() async {
    await _repo.set(_setupDoneKey, 'true');
  }

  Future<String?> getSetting(String key) async {
    return await _repo.get(key);
  }
}
