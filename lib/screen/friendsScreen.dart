import 'package:calendar_sharing/screen/addFriends.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/APIcalls.dart';
import '../services/UserData.dart';
import 'friendProfile.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {

  @override
  void initState() {
    super.initState();
    GoogleSignIn? gUser =
        Provider.of<UserData>(context, listen: false).googleUser;

    if (gUser?.currentUser != null) {
      // フレンド一覧を取得するロジックをここに追加
      // FIXME uidを適用させる
      // Provider.of<UserData>(context, listen: false).fetchFriends("kuroinusan");
    }
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);
    List<FriendInformation> friends = userData.friends;

    return Scaffold(
      appBar: AppBar(
        title: Text('フレンド'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddFriend())
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          if (friends.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // アイコン
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage("https://calendar-files.woody1227.com/user_icon/"+friends[index].uicon),
                              ),
                              SizedBox(width: 20),
                              // 名前
                              Text(
                                friends[index].uname,
                                style: TextStyle(fontSize: 25),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      // フレンドのプロフィールに飛ばす
                      print(friends[index].uid);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendProfile(friend: friends[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.no_accounts,
                    size: 200,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  Text(
                    'フレンドなし',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
