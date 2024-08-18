import 'package:calendar_sharing/screen/ContentsManage.dart';
import 'package:calendar_sharing/screen/profile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:calendar_sharing/screen/authenticate.dart';
import 'package:calendar_sharing/screen/Content.dart';
import 'package:calendar_sharing/screen/friendsScreen.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/APIcalls.dart';
import 'createContents.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _children = [
      FriendsScreen(), // Replace with your actual widgets
      ContentsManage(), // Access gUser through Provider
      Profile(),
      PlaceholderWidget(),
    ];
  }
  Future<void> _initializeApp() async {
    try {
      await _loadUserData();
      await _getDeviceId();
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
        throw e;
      }
    }
  }

  Future<void> _getDeviceId() async {
    try {
      FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
      String? deviceId = await _firebaseMessaging.getToken();
      if (deviceId != null) {
        AddDeviceID().addDeviceID(Provider.of<UserData>(context, listen: false).uid, deviceId);
      }
    } catch (e) {
      print('Error getting device ID: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.group
            ),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notification',
          ),
        ],
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text('Placeholder'),
      ),
    );
  }
}