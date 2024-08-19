import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:provider/provider.dart';

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
        title: Text('フレンドを追加する'),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                Text("@"),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ユーザーID',
                    ),
                    onChanged: (text) {
                      addFriendID = text;
                    },
                  ),
                ),
              ],
            ),

            //以下は保留
            Text("共有するコンテンツ"),

            //追加ボタン
            ElevatedButton(
              onPressed: () {
                //フレンドを検索→追加ボタンをそのウィンドウに配置
                Future<UserInformation> user = GetUser().getUser(addFriendID);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      insetPadding: EdgeInsets.all(10),
                      title: Text('フレンドの追加'),
                      content: AddFriendsSearchDialog(
                        user: user,
                        userData: userData,
                      ),
                    );
                  },
                );
              },
              child: Text('検索'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddFriendsSearchDialog extends StatelessWidget {
  const AddFriendsSearchDialog({
    super.key,
    required this.user,
    required this.userData,
  });

  final Future<UserInformation> user;
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      FutureBuilder<UserInformation>(
        future: user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(
                      "https://calendar-files.woody1227.com/user_icon/" +
                          snapshot.data!.uicon),
                ),
                Text(snapshot.data!.uname),
                Text("@${snapshot.data!.uid}"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () {
                        //フレンドを追加
                        Navigator.of(context).pop();
                        Future<void> addFriend = AddFriendRequest()
                            .addFriend(userData.uid!, snapshot.data!.uid);
                        showDialog(
                          context: context,
                          builder: (context) {
                            return addFriendResultDialog(addFriend);
                          },
                        );
                      },
                      child: Text('追加'),
                    ),
                  ],
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Column(
              children: [
                Text('ユーザーが見つかりませんでした'),
                closeButton(),
              ],
            );
          }
          // return CircularProgressIndicator();
          return Column(
            children: [
              CircularProgressIndicator(),
              Text('検索中...'),
            ],
          );
        },
      ),
    ]);
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
              if (snapshot.connectionState != ConnectionState.waiting) {
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
                      Text('すでにフレンドです', style: TextStyle(fontSize: 20)),
                    ],
                  );
                }else{
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
