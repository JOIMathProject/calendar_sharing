import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';

class FriendProfile extends StatefulWidget {
  final FriendInformation friend;
  FriendProfile({required this.friend});

  @override
  _FriendProfileState createState() => _FriendProfileState();
}

class _FriendProfileState extends State<FriendProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Profile'),
      ),
      body: Text("something"),
    );
  }
}