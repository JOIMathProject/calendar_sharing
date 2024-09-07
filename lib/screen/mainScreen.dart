import 'dart:async';

import 'package:calendar_sharing/screen/ContentsManage.dart';
import 'package:calendar_sharing/screen/MyContentsManage.dart';
import 'package:calendar_sharing/screen/loadingScreen.dart';
import 'package:calendar_sharing/screen/profile.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:calendar_sharing/screen/friendsScreen.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/APIcalls.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:badges/badges.dart' as badge;

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

List<GroupInformation> contents = [];
List<FriendRequestInformation> friendRequests = [];

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _children;
  bool _isLoading = true; // Loading state
  int unreadMessages = 0;
  int receivedRequestsCount = 0;
  @override
  void initState() {
    super.initState();
    _initializeApp();
    _children = [
      ContentsManage(contents: contents),
      FriendsScreen(),
      Profile(),
      MyContentsManage(),
    ];
    reloading();
  }

  void reloading() async {
    if (Provider.of<UserData>(context, listen: false).googleUser != null) {
      await new Future.delayed(new Duration(seconds: 2));
    }
    _reloadContents();
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
      }
      _reloadContents();
      _fetchReceivedRequests();
    });
  }

  Future<void> _initializeApp() async {
    try {
      await _loadUserData();
    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _loadUserData() async {
    GoogleSignIn? gUser =
        Provider.of<UserData>(context, listen: false).googleUser;
    if (gUser != null && gUser.currentUser != null) {
      try {
        UserInformation userInfo =
            await GetUserGoogleUid().getUserGoogleUid(gUser.currentUser!.id);
        Provider.of<UserData>(context, listen: false).updateUserInfo(userInfo);

        List<FriendInformation> friends =
            await GetFriends().getFriends(userInfo.uid);
        Provider.of<UserData>(context, listen: false).updateFriends(friends);
      } catch (e) {
        print('Error loading user data: $e');
        throw e;
      }
    }
  }

  Future<void> _reloadContents() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    if (uid != null) {
      var _MyCalendar = await GetMyCalendars().getMyCalendars(uid);
      var _MyContents = await GetMyContents().getMyContents(uid);
      Provider.of<UserData>(context, listen: false)
          .updateMyContents(_MyContents);
      Provider.of<UserData>(context, listen: false)
          .updateMyCalendar(_MyCalendar);
      contents = await GetGroupInfo().getGroupInfo(uid);
      _children[0] = ContentsManage(contents: contents);
      //contentsのunread_messagesの合計
      int unreadMessagescnt = 0;
      for (int i = 0; i < contents.length; i++) {
        unreadMessagescnt += contents[i].unread_messages;
      }
      unreadMessages = unreadMessagescnt;
      setState(() {});
    }
  }

  Future<void> _fetchReceivedRequests() async {
    try {
      UserData userData = Provider.of<UserData>(context, listen: false);
      String? uid = userData.uid;
      List<FriendRequestInformation> receivedRequests =
      await GetReceiveFriendRequest().getReceiveFriendRequest(userData.uid);
      List<FriendRequestInformation> sentRequests =
      await GetSentFriendRequest().getSentFriendRequest(userData.uid);
      receivedRequestsCount = receivedRequests.length;
      //二つをくっつける
      receivedRequests.addAll(sentRequests);
      Provider.of<UserData>(context, listen: false)
          .updateReceivedRequests(receivedRequests);
    } catch (e) {
      print("Error fetching requests: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SANDO',
          style: TextStyle(
            fontFamily: 'SmglMediumbold',
            fontSize: 50.0,
            color: GlobalColor.MainCol,
          ),
        ),
        backgroundColor: GlobalColor.SubCol,
        centerTitle: true,
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        backgroundColor: GlobalColor.MainCol,
        items: [
          BottomNavigationBarItem(
            icon: badge.Badge(
              child: Icon(
                Icons.home,
                color: _currentIndex != 0
                    ? GlobalColor.bottomBar
                    : GlobalColor.MainCol,
              ),
              badgeContent: Text(
                unreadMessages.toString(),
                style: TextStyle(color: Colors.white),
              ),
              showBadge: unreadMessages != 0,
            ),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: badge.Badge(
              child: Icon(
                Icons.group,
                color: _currentIndex != 1
                    ? GlobalColor.bottomBar
                    : GlobalColor.MainCol,
              ),
              badgeContent: Text(
                receivedRequestsCount.toString(),
                style: TextStyle(color: Colors.white),
              ),
              showBadge: receivedRequestsCount != 0,
            ),
            label: 'フレンド',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _currentIndex != 2
                  ? GlobalColor.bottomBar
                  : GlobalColor.MainCol,
            ),
            label: 'プロフィール',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_month,
              color: _currentIndex != 3
                  ? GlobalColor.bottomBar
                  : GlobalColor.MainCol,
            ),
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
