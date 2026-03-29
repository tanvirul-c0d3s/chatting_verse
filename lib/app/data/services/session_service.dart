import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  Future<void> saveLogin({required String uid, required String email}) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('uid', uid);
    await pref.setString('email', email);
  }

  Future<String?> getUid() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('uid');
  }

  Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove('uid');
    await pref.remove('email');
  }
}