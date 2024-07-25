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
        //ボタン
        actions: [
          IconButton(
            icon: Icon(
              Icons.block,
              color: Colors.red,
              size: 30,
            ),
            onPressed: () {
              //フレンド削除のアクション
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          //真ん中に寄せる
          children: [
            //アイコン
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
            ),
            //名前
            SizedBox(height: 20),
            Text(
              widget.friend.uname,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            //uid
            SizedBox(height: 20),
            Text(
              "uid:"+widget.friend.uid,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            Row(
              //ボタンを横に並べる
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //コンテンツのボタンとメッセージのボタン
                ElevatedButton(
                  onPressed: () {
                    //コンテンツのボタンのアクション
                  },
                  child: Icon(Icons.content_copy),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    //メッセージのボタンのアクション
                  },
                  child: Icon(Icons.message),
                ),
              ],
            )
          ],
        ),
      )
    );
  }
}