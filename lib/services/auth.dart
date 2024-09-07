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
    serverClientId:
    '213698548031-5elgmjrqi6vof2nos67ne6f233l5t1uo.apps.googleusercontent.com',
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
          'client_id':
          '213698548031-5elgmjrqi6vof2nos67ne6f233l5t1uo.apps.googleusercontent.com',
          'client_secret': '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',
          'redirect_uri': 'https://calendar-api.woody1227.com/',
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode != 200) {
        // Token exchange failed
        _showTokenExchangeError(context, response.statusCode);
        return null;  // Handle the failure
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('refresh_token')) {
        print('Refresh Token: ${data['refresh_token']}');
      } else {
        throw 'No refresh token in response';
      }

      // Successfully retrieved tokens
      print('Access Token: ${data['access_token']}');
      print('ID Token: ${data['id_token']}');
      print('Current User: ${_googleSignIn.currentUser}');

      // Check if the account exists using the Google UID
      try {
        await GetUserGoogleUid().getUserGoogleUid(result.id);
      } catch (e) {
        if (e.toString().contains('404')) {
          // Account doesn't exist, redirect to the CreateUserScreen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateUserScreen(
                result: result,
                refresh_token: data['refresh_token'],
              ),
            ),
          );
        }
      }

      // Update user data in the app state
      await _googleSignIn.authenticatedClient();
      Provider.of<UserData>(context, listen: false)
          .updateGoogleUser(_googleSignIn);

      return _googleSignIn;
    } catch (e) {
      print('Error: $e');
      _showGeneralError(context, e);
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

  // Show error when token exchange fails
  void _showTokenExchangeError(BuildContext context, int statusCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Token Exchange Failed'),
          content: Text('Failed to exchange token with status code $statusCode. '
              'Please check your connection and try again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                signInWithGoogle(context); // Retry signing in
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Show general error in case something else fails
  void _showGeneralError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred: $error'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
