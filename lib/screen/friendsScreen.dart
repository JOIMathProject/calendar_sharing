import 'package:calendar_sharing/screen/addFriends.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'friendProfile.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  Future<List<FriendInformation>>? friends;

  @override
  void initState() {
    super.initState();
    GoogleSignIn? gUser =
        Provider.of<UserData>(context, listen: false).googleUser;
    if (gUser?.currentUser != null) {
      //ここでフレンド一覧を取得する
      //FIXME uidを適用させる
      friends = GetFriends().getFriends("kuroinusan");
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
          //フレンド一覧を表示する
          SizedBox(height: 20),
          FutureBuilder<List<FriendInformation>>(
            future: friends,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError &&
                  snapshot.error != "Failed to get friends: 404") {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                return Container(
                  child: Expanded(
                    child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      //アイコン
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.white,
                                        backgroundImage: NetworkImage("https://calendar-files.woody1227.com/user_icon/"+snapshot.data![index].uicon),
                                      ),
                                      SizedBox(width: 20),
                                      //名前
                                      Text(
                                        snapshot.data![index].uname,
                                        style: TextStyle(fontSize: 25),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              //フレンドのプロフィールに飛ばす
                              print(snapshot.data![index].uid);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FriendProfile(
                                          friend: snapshot.data![index])));
                            },
                          );
                        }),
                  ),
                );
              } else {
                return Center(
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
                      )
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
