import 'package:calendar_sharing/screen/ContentsManage.dart';
import 'package:calendar_sharing/screen/profile.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:calendar_sharing/screen/authenticate.dart';
import 'package:calendar_sharing/screen/home.dart';
import 'package:calendar_sharing/screen/friendsScreen.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    _children = [
      FriendsScreen(), // Replace with your actual widgets
      ContentsManage(), // Access gUser through Provider
      Profile(),
      PlaceholderWidget(),
    ];
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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