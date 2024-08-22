import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import 'Content.dart';

class FriendProfile extends StatefulWidget {
  final FriendInformation friend;
  FriendProfile({required this.friend});

  @override
  _FriendProfileState createState() => _FriendProfileState();
}

class _FriendProfileState extends State<FriendProfile> {
  Future<String?> _checkFriend(String uid, String friendUid) async {
    return await CheckFriend().checkFriend(uid, friendUid);
  }

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
            SizedBox(height: 80),
            CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage("https://calendar-files.woody1227.com/user_icon/"+widget.friend.uicon),
            ),
            //名前
            SizedBox(height: 30),
            Text(
              widget.friend.uname,
              style: TextStyle(
                fontSize: 30,
              ),
            ),
            //uid
            Text(
              "@"+widget.friend.uid,
              style: TextStyle(
                fontSize: 25,
              ),
            ),
            SizedBox(height: 20),
            Row(
              //ボタンを横に並べる
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //コンテンツのボタンとメッセージのボタン
                ElevatedButton(
                  onPressed: () async {
                    String? uid = Provider.of<UserData>(context, listen: false).uid;
                    String? groupId = await _checkFriend(uid!, widget.friend.uid);
                    if (groupId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Home(
                            groupId: groupId,
                            groupName: widget.friend.uid,
                            startOnChatScreen: false,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(30),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 40,
                  ),
                ),
                SizedBox(width: 50),
                ElevatedButton(
                  onPressed: () async {
                    String? uid = Provider.of<UserData>(context, listen: false).uid;
                    String? groupId = await _checkFriend(uid!, widget.friend.uid);
                    if (groupId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Home(
                            groupId: groupId,
                            groupName: widget.friend.uid,
                            startOnChatScreen: true,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(30),
                  ),
                  child: Icon(
                    Icons.message,
                    size: 40,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
