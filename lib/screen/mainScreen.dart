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

final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  MainScreen({Key? key}) : super(key: mainScreenKey); // Assign the GlobalKey

  @override
  _MainScreenState createState() => _MainScreenState();
}

List<GroupInformation> contents = [];
List<FriendRequestInformation> friendRequests = [];


class _MainScreenState extends State<MainScreen> {
  late List<Widget> _children;
  bool _isLoading = true; // Loading state
  int unreadMessages = 0;
  int receivedRequestsCount = 0;

  int _currentIndex = 0;
  void updateTab(int index) {
    print('updateTab');
    setState(() {
      _currentIndex = index;
    });
  }
  @override
  void initState() {
    super.initState();
    _initializeApp();
    _children = [
      ContentsManage(contents: contents),
      MyContentsManage(),
      FriendsScreen(),
      Profile(),
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
      List<CalendarInformation> _MyCalendar = await GetMyCalendars().getMyCalendars(uid);
      _MyCalendar = _MyCalendar.where((calendar) => calendar.accessRole != 'reader').toList();
      var _MyContents = await GetMyContents().getMyContents(uid);


      List<FriendInformation> friends = await GetFriends().getFriends(uid);
      Provider.of<UserData>(context, listen: false).updateFriends(friends);
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
          'Sando',
          style: TextStyle(
            fontFamily: 'SmglMediumbold',
            fontWeight: FontWeight.bold,
            fontSize: 50.0,
            color: GlobalColor.MainCol,
          ),
        ),
        backgroundColor: GlobalColor.AppBarCol,
        centerTitle: true,
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensure fixed type
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        //backgroundColor: GlobalColor.backGroundCol, // Set to the intended color
        selectedItemColor: GlobalColor.MainCol, // Optional: Set selected item color
        unselectedItemColor: GlobalColor.bottomBar, // Optional: Set unselected items color
        items: [
          BottomNavigationBarItem(
            icon: badge.Badge(
              child: Icon(
                Icons.home,
              ),
              badgeContent: Text(
                '$unreadMessages',
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
              badgeStyle: badge.BadgeStyle(
                padding: EdgeInsets.all(5),
                borderRadius: BorderRadius.circular(10),
              ),
              showBadge: unreadMessages != 0,
            ),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_month,
              // Removed color from here to use selected/unselected colors
            ),
            label: 'マイコンテンツ',
          ),
          BottomNavigationBarItem(
            icon: badge.Badge(
              child: Icon(
                Icons.group,
                // Removed color from here to use selected/unselected colors
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
              // Removed color from here to use selected/unselected colors
            ),
            label: 'プロフィール',
          ),
        ],
      ),

    );
  }
}