import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import 'package:calendar_sharing/services/APIcalls.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  Future<List<FriendInformation>>? friends;
  @override
  void initState() {
    super.initState();
    GoogleSignIn? gUser = Provider.of<UserData>(context, listen: false).googleUser;
    if (gUser?.currentUser != null) {
      //ここでフレンド一覧を取得する
      friends = GetFriends().getFriends("kuroinusan");
      //friends = GetFriends().getFriends(gUser?.currentUser!.id);
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
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            //フレンド一覧を表示する
            FutureBuilder<List<FriendInformation>>(
              future: friends,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting){
                  return CircularProgressIndicator();
                }else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }else if (snapshot.hasData){
                  print(snapshot.data);
                  return Container(
                    child: Expanded(
                      child:ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Row(
                                children: [
                                  //アイコン(本当はここに画像を代入?)
                                  Icon(Icons.person),
                                  SizedBox(width: 25),
                                  //名前
                                  Text(
                                    snapshot.data![index].uname,
                                    style: TextStyle(fontSize: 25),
                                  ),
                                ],
                              );
                              /*return ListTile(
                                leading: Icon(Icons.person),
                                title: Text(snapshot.data![index]),
                              );*/
                            }
                        ),
                    ),
                  );
                }else{
                  return Text('No data');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
