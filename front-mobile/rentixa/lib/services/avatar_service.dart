import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarService {
  /// 📷 Choisir une image et la sauvegarder localement
  static Future<String?> pickAndSaveAvatar(String email) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'avatar_${email.replaceAll('@', '_').replaceAll('.', '_')}.png';

    final savedImage =
        await File(pickedFile.path).copy('${directory.path}/$fileName');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_$email', savedImage.path);

    return savedImage.path;
  }

  /// 👤 Récupérer l’avatar
  static Future<String?> getAvatar(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('avatar_$email');
  }

  /// 🗑️ Supprimer l’avatar
  static Future<void> removeAvatar(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('avatar_$email');

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await prefs.remove('avatar_$email');
  }
}
