import '../models/user_preference.dart';
import '../services/storage_service.dart';

class UserPreferenceRepository {

  UserPreferenceRepository({required this.userId});
  final String userId;

  Future<UserPreference> getOrCreate() async {
    return StorageService.getUserPreference(userId);
  }

  Future<UserPreference> get() async {
    return StorageService.getUserPreference(userId);
  }

  Future<void> save(UserPreference preference) async {
    await StorageService.saveUserPreference(preference);
  }
}
