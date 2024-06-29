import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserData extends ChangeNotifier {
  GoogleSignIn? googleUser;

  void updateGoogleUser(GoogleSignIn? newGoogleUser) {
    googleUser = newGoogleUser;
    notifyListeners();
  }
}