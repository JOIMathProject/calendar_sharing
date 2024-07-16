import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import 'package:calendar_sharing/services/APIcalls.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class People {}

class _FriendsScreenState extends State<FriendsScreen> {

  @override
  void initState() {
    super.initState();
    GoogleSignIn? gUser = Provider.of<UserData>(context, listen: false).googleUser;
    if (gUser?.currentUser != null) {
      //ここでフレンド一覧を取得する

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('フレンド'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt),
            onPressed: () {
              //フレンド追加のクラスに飛ばす
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text('フレンド一覧'),
            //フレンド一覧を表示する
            ListView.builder(),
          ],
        ),
      ),
    );
  }
}
