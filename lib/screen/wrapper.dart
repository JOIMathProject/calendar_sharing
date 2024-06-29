import 'package:flutter/material.dart';
import '../services/UserData.dart';
import 'authenticate.dart';
import 'home.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    GoogleSignIn? gUser = Provider.of<UserData>(context).googleUser;
    if (gUser != null && gUser.currentUser != null) {
      return Home(gUser: gUser); // Show the home screen if the user is logged in
    } else {
      return Authenticate(); // Show the authenticate screen if the user is not logged in
    }
  }
}