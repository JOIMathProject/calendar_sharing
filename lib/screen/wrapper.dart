import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import '../services/UserData.dart';
import '../services/sign_in.dart';
import 'authenticate.dart';
import 'loadingScreen.dart';
import 'mainScreen.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as googleAPI;

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      googleAPI.CalendarApi.calendarScope,
    ],
    forceCodeForRefreshToken: false,
    serverClientId: '213698548031-5elgmjrqi6vof2nos67ne6f233l5t1uo.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _signInSilently();
    } catch (e) {
      print('Error during initialization: $e');
      _navigateToAuthenticate();
    }
  }
  Future<void> _signInSilently() async {
    try {
      final result = await _googleSignIn.signInSilently();

      if (result != null) {
        // Attempt to verify if the Google account is linked to an existing account
        try {
          await GetUserGoogleUid().getUserGoogleUid(result.id);
          // Account exists, update the user data and navigate to MainScreen
          Provider.of<UserData>(context, listen: false).updateGoogleUser(_googleSignIn);
          _navigateToMainScreen();
        } catch (error) {
          if (error.toString().contains('404')) {
            // Account doesn't exist, navigate to the Authenticate screen
            _navigateToAuthenticate();
          } else {
            // Handle other types of errors (e.g., network issues)
            print('Error verifying account existence: $error');
            _navigateToAuthenticate();
          }
        }
      } else {
        _navigateToAuthenticate();
      }
    } catch (e) {
      print('Error signing in silently: $e');
      _navigateToAuthenticate();
    }
  }

  // Helper function to navigate to MainScreen
  void _navigateToMainScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  // Helper function to navigate to Authenticate screen
  void _navigateToAuthenticate() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignIn()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen();
  }
}
