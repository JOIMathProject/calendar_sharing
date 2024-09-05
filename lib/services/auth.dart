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
            icon = 'default.png';
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
