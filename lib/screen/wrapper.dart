import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import '../services/UserData.dart';
import 'authenticate.dart';
import 'Content.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'mainScreen.dart';
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
    _signInSilently();
  }

  Future<void> _signInSilently() async {
    try {
      final result = await _googleSignIn.signInSilently();
      if (result != null) {
        Provider.of<UserData>(context, listen: false).updateGoogleUser(_googleSignIn);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _loadUserData() async {
    GoogleSignIn? gUser = Provider.of<UserData>(context, listen: false).googleUser;
    if (gUser != null && gUser.currentUser != null) {
      try {
        UserInformation userInfo = await GetUserGoogleUid().getUserGoogleUid(gUser.currentUser!.id);
        Provider.of<UserData>(context, listen: false).updateUserInfo(userInfo);

        List<FriendInformation> friends = await GetFriends().getFriends(userInfo.uid);
        Provider.of<UserData>(context, listen: false).updateFriends(friends);
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    GoogleSignIn? gUser = Provider.of<UserData>(context).googleUser;
    if (gUser != null && gUser.currentUser != null) {
      _loadUserData(); // Load the user data asynchronously
      return MainScreen(); // Show the main screen if the user is logged in
    } else {
      return Authenticate(); // Show the authenticate screen if the user is not logged in
    }
  }
}
