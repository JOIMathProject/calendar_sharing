import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import 'Content.dart';
import '../setting/color.dart' as GlobalColor;

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
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("フレンド削除"),
                    content: Text("本当に削除しますか？"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("キャンセル"),
                      ),
                      TextButton(
                        onPressed: () async {
                          String? uid =
                              Provider.of<UserData>(context, listen: false).uid;
                          await DeleteFriend()
                              .deleteFriend(uid!, widget.friend.uid);

                          List<FriendInformation> friends =
                          await GetFriends().getFriends(uid);
                          Provider.of<UserData>(context, listen: false).updateFriends(friends);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text("削除"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        backgroundColor: GlobalColor.SubCol,
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
              backgroundImage: NetworkImage(
                  "https://calendar-files.woody1227.com/user_icon/" +
                      widget.friend.uicon),
            ),
            SizedBox(height: 30),
            Text(
              widget.friend.uname,
              style: TextStyle(
                fontSize: 30,
              ),
            ),
            //uid
            Text(
              "@" + widget.friend.uid,
              style: TextStyle(
                fontSize: 25,
              ),
            ),
            SizedBox(height: 80),
            SizedBox(
              width: 300,
              child:Container(
              decoration: BoxDecoration(
                color: GlobalColor.AppBarCol, // Bright orange background
                borderRadius: BorderRadius.circular(40.0), // Rounded corners
              ),
              padding: EdgeInsets.symmetric(vertical: 20.0), // Padding inside the container
              child: Row(
                // ボタンを横に並べる
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // コンテンツのボタンとメッセージのボタン
                  ElevatedButton(
                    onPressed: () async {
                      String? uid = Provider.of<UserData>(context, listen: false).uid;
                      String? groupId = await _checkFriend(uid!, widget.friend.uid);

                      bool opened = await GetOpened().getOpened(uid, groupId!) == 1;
                      if (groupId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Home(
                              groupId: groupId,
                              groupName: widget.friend.uname,
                              startOnChatScreen: false,
                              firstVisit: opened,
                              is_frined: true,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(30),
                      backgroundColor: GlobalColor.MainCol, // Optional: Button background color
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: GlobalColor.SubCol,
                      size: 40,
                    ),
                  ),
                  SizedBox(width: 40),
                  ElevatedButton(
                    onPressed: () async {
                      String? uid = Provider.of<UserData>(context, listen: false).uid;
                      String? groupId = await _checkFriend(uid!, widget.friend.uid);
                      bool opened = await GetOpened().getOpened(uid, groupId!) == 1;
                      if (groupId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Home(
                              groupId: groupId,
                              groupName: widget.friend.uname,
                              startOnChatScreen: true,
                              firstVisit: opened,
                              is_frined: true,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(30),
                      backgroundColor: GlobalColor.MainCol, // Optional: Button background color
                    ),
                    child: Icon(
                      Icons.message,
                      color: GlobalColor.SubCol,
                      size: 40,
                    ),
                  ),
                ],
              ),
            )
            ),
          ],
        ),
      ),
    );
  }
}
