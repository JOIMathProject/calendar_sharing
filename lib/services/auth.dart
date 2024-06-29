import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as googleAPI;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:provider/provider.dart';
import 'UserData.dart';
import 'package:flutter/material.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      googleAPI.CalendarApi.calendarScope,
    ],
  );

  Future<GoogleSignIn?> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signIn().then((result) {
        result?.authentication.then((googleKey) {
          print(googleKey.accessToken);
          print(googleKey.idToken);
          print(_googleSignIn.currentUser);
        }).catchError((err) {
          print('inner error');
        });
      }).catchError((err) {
        print('error occured');
      });

      await _googleSignIn.authenticatedClient();
      Provider.of<UserData>(context, listen: false).updateGoogleUser(_googleSignIn);

      return _googleSignIn;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future signOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      Provider.of<UserData>(context, listen: false).updateGoogleUser(null);
    } catch (e) {
      print(e.toString());
    }
  }
}