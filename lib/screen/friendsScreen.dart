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
  bool _isDataFetched = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      GoogleSignIn? gUser =
          Provider.of<UserData>(context, listen: false).googleUser;

      if (gUser?.currentUser != null) {
        // Fetch friends after the widget is fully inserted into the widget tree
        _fetchFriends();
        _fetchReceivedRequests();
        _isDataFetched = true; // Mark the data as fetched
      }
    }
  }

  Future<void> _fetchFriends() async {
    try {
      UserData userData = Provider.of<UserData>(context, listen: false);
      List<FriendInformation> friends =
      await GetFriends().getFriends(userData.uid);
      Provider.of<UserData>(context, listen: false).updateFriends(friends);
    } catch (e) {
      print("Error fetching friends: $e");
    }
  }

  Future<void> _fetchReceivedRequests() async {
    try {
      UserData userData = Provider.of<UserData>(context, listen: false);
      String? uid = userData.uid;
      List<FriendRequestInformation> receivedRequests =
      await GetReceiveFriendRequest().getReceiveFriendRequest(userData.uid);
      List<FriendRequestInformation> sentRequests =
      await GetSentFriendRequest().getSentFriendRequest(userData.uid);
      //二つをくっつける
      receivedRequests.addAll(sentRequests);
      Provider.of<UserData>(context, listen: false)
          .updateReceivedRequests(receivedRequests);
    } catch (e) {
      print("Error fetching requests: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);
    List<FriendInformation> friends = userData.friends;
    List<FriendRequestInformation> requests = userData.receivedRequests;

    return Scaffold(
      appBar: AppBar(
        title: Text('フレンド'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddFriend()));
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'フレンド'),
                Tab(text: 'リクエスト'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Friends(friends),
                  Requests(requests, userData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Column Requests(List<FriendRequestInformation> requests, UserData userData) {
    return Column(
      children: [
        SizedBox(height: 20),
        if (requests.isNotEmpty)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchReceivedRequests,
              child: ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  if (requests[index].isReceived){
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // アイコン
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(
                                    "https://calendar-files.woody1227.com/user_icon/" +
                                        requests[index].uicon),
                              ),
                              SizedBox(width: 20),
                              // 名前
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    requests[index].uname,
                                    style: TextStyle(fontSize: 25),
                                  ),
                                  Text(
                                    'リクエストを受信しています',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(),
                              // 承認ボタン
                              IconButton(
                                icon: Icon(Icons.check),
                                onPressed: () async {
                                  await AcceptFriendRequest()
                                      .acceptFriendRequest(
                                      userData.uid, requests[index].uid);
                                  _fetchReceivedRequests();
                                  _fetchFriends();
                                },
                              ),
                              // 拒否ボタン
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () async {
                                  await DeleteFriendRequest()
                                      .deleteFriendRequest(
                                      userData.uid, requests[index].uid);
                                  _fetchReceivedRequests();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }else{
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // アイコン
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(
                                    "https://calendar-files.woody1227.com/user_icon/" +
                                        requests[index].uicon),
                              ),
                              SizedBox(width: 20),
                              // 名前
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    requests[index].uname,
                                    style: TextStyle(fontSize: 25),
                                  ),
                                  Text(
                                    'リクエスト送信済み',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(),
                              // 削除ボタン
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () async {
                                  await DeleteFriendRequest()
                                      .deleteFriendRequest(requests[index].uid,userData.uid);
                                  _fetchReceivedRequests();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchReceivedRequests,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.no_accounts,
                            size: 200,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          Text(
                            'リクエストなし',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Column Friends(List<FriendInformation> friends) {
    return Column(children: [
      SizedBox(height: 20),
      if (friends.isNotEmpty)
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchFriends, // The function to reload friends
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
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
                              backgroundImage: NetworkImage(
                                  "https://calendar-files.woody1227.com/user_icon/" +
                                      friends[index].uicon),
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
                        builder: (context) =>
                            FriendProfile(friend: friends[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        )
      else
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchFriends,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
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
                );
              },
            ),
          ),
        )
    ]);
  }
}
