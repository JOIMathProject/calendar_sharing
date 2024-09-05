import 'package:calendar_sharing/screen/CreateUser.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:googleapis/calendar/v3.dart' as googleAPI;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:provider/provider.dart';
import 'UserData.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      googleAPI.CalendarApi.calendarScope,
    ],
    forceCodeForRefreshToken: true,
    serverClientId: '213698548031-5elgmjrqi6vof2nos67ne6f233l5t1uo.apps.googleusercontent.com',
  );

  Future<GoogleSignIn?> signInWithGoogle(BuildContext context) async {
    try {
      final result = await _googleSignIn.signIn();
      if (result == null) {
        print('Google Sign-In aborted');
        return null;
      }
      final googleKey = await result.authentication;
      final url = Uri.parse('https://oauth2.googleapis.com/token');

      final response = await http.post(
        url,
        headers: {'Content-type': 'application/x-www-form-urlencoded'},
        body: {
          'code': result.serverAuthCode!,
          'client_id': '213698548031-5elgmjrqi6vof2nos67ne6f233l5t1uo.apps.googleusercontent.com',
          'client_secret': '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',
          'redirect_uri': 'https://calendar-api.woody1227.com/',
          'grant_type': 'authorization_code',
        },
      );
      print(result.id);

      if (response.statusCode != 200) {
        throw 'Token exchange failed: ${response.statusCode}';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('refresh_token')) {
        // Here is your refresh token, store it in a secure way
        print('Refresh Token: ${data['refresh_token']}');
      } else {
        throw 'No refresh token in response';
      }

      print('Access Token: ${data['access_token']}');
      print('ID Token: ${data['id_token']}');
      print('Current User: ${_googleSignIn.currentUser}');

      try {
        await GetUserGoogleUid().getUserGoogleUid(result.id);
      } catch (e) {
        // If the user does not exist (i.e., a 404 error is returned), create the user
        if (e.toString().contains('404')) {
          //ここでユーザー登録のページに飛ばし、ユーザー情報を入力後、戻ってきたときにユーザー情報を登録する
          UserinfoIcon userInformation = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateUserScreen()),
          );
          late final String icon;
          final imageFile = userInformation.imageFile;
          if (imageFile != null) {
            List<int> imageBytes = await File(imageFile.path).readAsBytesSync();
            icon = base64Encode(imageBytes);
          } else {
            icon = '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';
          }
          await CreateUser().createUser(UserInformation(
            google_uid: result.id,
            uid: userInformation.userInformation.uid,
            uname: userInformation.userInformation.uname,
            uicon: icon,
            refreshToken: data['refresh_token'],
            mailAddress: result.email,
          ));
        }
      }

      await _googleSignIn.authenticatedClient();
      Provider.of<UserData>(context, listen: false).updateGoogleUser(_googleSignIn);

      return _googleSignIn;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future signOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      Provider.of<UserData>(context, listen: false).updateGoogleUser(null);
    } catch (e) {
      print('Error: $e');
    }
  }
}
