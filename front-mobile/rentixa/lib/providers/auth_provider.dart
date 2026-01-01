import 'package:flutter/material.dart';

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
} 