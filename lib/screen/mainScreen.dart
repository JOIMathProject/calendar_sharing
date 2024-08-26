import 'package:calendar_sharing/screen/ContentsManage.dart';
import 'package:calendar_sharing/screen/MyContentsManage.dart';
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
import '../setting/color.dart' as GlobalColor;
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _children;
  bool _isLoading = true;  // Loading state

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _children = [
      ContentsManage(),
      FriendsScreen(),
      Profile(),
      MyContentsManage(),
    ];
  }

  Future<void> _initializeApp() async {
    try {
      await _loadUserData();
      await _getDeviceId();
    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      setState(() {
        _isLoading = false;  // Stop loading
      });
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
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Or any other loading icon
        ),
      );
    }
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        backgroundColor: GlobalColor.Menu_bar,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
              color: _currentIndex != 0 ? GlobalColor.Unselected : GlobalColor.MainCol,
            ),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group,
              color: _currentIndex != 1 ? GlobalColor.Unselected : GlobalColor.MainCol,
            ),
            label: 'フレンド',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person
              ,color: _currentIndex != 2 ? GlobalColor.Unselected : GlobalColor.MainCol,),
            label: 'プロフィール',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month
              ,color: _currentIndex != 3 ? GlobalColor.Unselected : GlobalColor.MainCol,),
            label: 'マイコンテンツ',
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