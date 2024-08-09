import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
class AddFriend extends StatefulWidget {
  @override
  _AddFriendState createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  String addFriendID = "";
  @override
  Widget build(BuildContext context) {
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
                //APIを叩く
                //FIXME uidを適用させる
                Future<void> result = AddFriendRequest().addFriend("kuroinusan", addFriendID);

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('フレンド追加'),
                        content: FutureBuilder<void>(
                          future: result,
                          builder: (context,snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("処理中...");
                            } else if (snapshot.hasError) {
                              //FIXME uidに対応させる
                              if (snapshot.error ==
                                  'Failed to add friend: 500' &&
                                  addFriendID != 'kuroinusan') {
                                return Text('ユーザーが見つかりません');
                              } else if (addFriendID == 'kuroinusan' &&
                                  snapshot.error ==
                                      'Failed to add friend: 500') {
                                return Text(
                                    '自分自身を追加することはできません');
                              } else if (snapshot.error ==
                                  'Failed to add friend: 409') {
                                return Text('既にフレンド登録されています');
                              } else {
                                return Text('エラーが発生しました');
                              }
                            }else{
                              return Text("フレンド追加が完了しました");
                            }
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                //});
              },
              child: Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}