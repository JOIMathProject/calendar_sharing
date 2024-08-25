import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:provider/provider.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;

class AddFriend extends StatefulWidget {
  @override
  _AddFriendState createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  String addFriendID = "";

  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 1), // Adds flexible space at the top
            Text(
              'フレンドリクエストを送る',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Spacer(flex: 1), // Adds space between the title and the TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                          prefixText: '@', // Use prefixText instead of prefix
                          hintText: 'ユーザーIDを入力',
                          fillColor: GlobalColor.Unselected,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onChanged: (text) {
                          addFriendID = text;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(flex: 5), // Adds more space between the TextField and the button
            SizedBox(
              height: 50,
              width: 400,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                onPressed: () {
                  Future<void> addFriend = AddFriendRequest()
                      .addFriend(userData.uid!, addFriendID);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return addFriendResultDialog(addFriend);
                    },
                  );
                },
                child: Text(
                  'フレンドリクエストを送る',
                  style: TextStyle(fontSize: 20, color: GlobalColor.SubCol),
                ),
              ),
            ),
            Spacer(flex: 1), // Adds space at the bottom for better balancing
          ],
        ),
      ),
    );
  }

  AlertDialog addFriendResultDialog(Future<void> addFriend) {
    return AlertDialog(
      title: Text('フレンドの追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<void>(
            future: addFriend,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.waiting && !snapshot.hasError) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                    Text('フレンド申請を送信しました'),
                  ],
                );
              } else if (snapshot.hasError) {
                if (snapshot.error == 'Failed to add friend: 409') {
                  return Column(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                      Text('すでにフレンドもしくは送信済みです', style: TextStyle(fontSize: 20)),
                    ],
                  );
                } else {
                  print(snapshot.error.toString());
                  return Column(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                      Text('エラーが発生しました'),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      )
                    ],
                  );
                }
              }
              return CircularProgressIndicator();
            },
          ),
        ],
      ),
      actions: [
        closeButton(),
      ],
    );
  }
}

class closeButton extends StatelessWidget {
  const closeButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: Text('閉じる'),
    );
  }
}
