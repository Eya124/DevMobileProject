import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? userId;
  String? firstName;
  String? lastName;
  String? email;

  void setUserData(String id, String first, String last, String userEmail) {
    userId = id;
    firstName = first;
    lastName = last;
    email = userEmail;
    notifyListeners();
  }

  void setUserId(String id) {
    userId = id;
    notifyListeners();
  }

  String get userInitials {
    print('AuthProvider - firstName: "$firstName", lastName: "$lastName"');
    if (firstName != null && lastName != null && firstName!.isNotEmpty && lastName!.isNotEmpty) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    } else if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    } else if (lastName != null && lastName!.isNotEmpty) {
      return lastName![0].toUpperCase();
    }
    return 'HE'; // Default initials
  }

  void clear() {
    userId = null;
    firstName = null;
    lastName = null;
    email = null;
    notifyListeners();
  }
  Future<void> restoreSession() async {
  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString('token');
  if (token == null) return;

  userId = prefs.getString('userId');
  firstName = prefs.getString('firstName');
  lastName = prefs.getString('lastName');
  email = prefs.getString('email');

  notifyListeners();
}

} 

