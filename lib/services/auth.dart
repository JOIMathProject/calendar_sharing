import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as googleAPI;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:provider/provider.dart';
import 'UserData.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      googleAPI.CalendarApi.calendarScope,
    ],
    clientId: '213698548031-5elgmjrqi6vof2nos67ne6f233l5t1uo.apps.googleusercontent.com',
  );

  Future<GoogleSignIn?> signInWithGoogle(BuildContext context) async {
    try {
      final result = await _googleSignIn.signIn();
      if (result == null) {
        print('Google Sign-In aborted');
        return null;
      }

      final googleKey = await result.authentication;
      final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=AIzaSyDGdPfqhFIZRdy-Y8-_QOJ072rSwnCTcxo');

      final response = await http.post(
        url,
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({
          'postBody': 'id_token=${googleKey.idToken}&providerId=google.com',
          'requestUri': 'http://localhost',
          'returnIdpCredential': true,
          'returnSecureToken': true
        }),
      );

      if (response.statusCode != 200) {
        throw 'Refresh token request failed: ${response.statusCode}';
      }

      final data = Map<String, dynamic>.of(jsonDecode(response.body));
      if (data.containsKey('refreshToken')) {
        // Here is your refresh token, store it in a secure way
        print('Refresh Token: ${data['refreshToken']}');
      } else {
        throw 'No refresh token in response';
      }

      print('Access Token: ${googleKey.accessToken}');
      print('ID Token: ${googleKey.idToken}');
      print('Current User: ${_googleSignIn.currentUser}');

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