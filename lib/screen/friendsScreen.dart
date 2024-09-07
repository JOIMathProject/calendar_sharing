import 'package:calendar_sharing/screen/addFriends.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/chat/v1.dart';
import 'package:provider/provider.dart';
import '../services/APIcalls.dart';
import '../services/UserData.dart';
import 'friendProfile.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:calendar_sharing/setting/size_config.dart';
import 'package:badges/badges.dart' as badge;

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _isDataFetched = false;
  final TextEditingController _searchController = TextEditingController();
  int receivedRequestCount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      List<FriendRequestInformation> receivedRequests =
          await GetReceiveFriendRequest().getReceiveFriendRequest(userData.uid);
      List<FriendRequestInformation> sentRequests =
          await GetSentFriendRequest().getSentFriendRequest(userData.uid);
      receivedRequestCount = receivedRequests.length;
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
    SizeConfig().init(context);
    List<FriendInformation> friends = userData.friends;
    List<FriendRequestInformation> requests = userData.receivedRequests;

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                const Tab(text: 'フレンド'),
                Tab(
                    child: badge.Badge(
                  badgeContent: null,
                  showBadge: receivedRequestCount > 0,
                  child: const Text('リクエスト'),
                )),
              ],
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: GlobalColor.MainCol,
                    width: 3.0,
                  ),
                ),
              ),
              labelStyle: const TextStyle(fontSize: 16.0),
              dividerColor: GlobalColor.Unselected,
              labelColor: GlobalColor.MainCol,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
                  context, MaterialPageRoute(builder: (context) => AddFriend()))
              .then((value) => () {
                    _fetchFriends();
                    _fetchReceivedRequests();
                    setState(() {});
                  });
        },
        backgroundColor: GlobalColor.MainCol,
        child: Icon(Icons.person_add, color: GlobalColor.SubCol),
      ),
    );
  }

  Column Requests(List<FriendRequestInformation> requests, UserData userData) {
    return Column(
      children: [
        SizedBox(height: SizeConfig.blockSizeVertical! * 2),
        if (requests.isNotEmpty)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchReceivedRequests,
              child: ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  if (requests[index].isReceived) {
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
                                    "https://calendar-files.woody1227.com/user_icon/${requests[index].uicon}"),
                              ),
                              SizedBox(
                                  width: SizeConfig.blockSizeHorizontal! * 3),
                              // 名前
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    requests[index].uname,
                                    style: const TextStyle(fontSize: 25),
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
                              const Spacer(),
                              // 承認ボタン
                              IconButton(
                                icon: const Icon(Icons.check),
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
                                icon: const Icon(Icons.close),
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
                  } else {
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
                                    "https://calendar-files.woody1227.com/user_icon/${requests[index].uicon}"),
                              ),
                              SizedBox(
                                  width: SizeConfig.blockSizeHorizontal! * 3),
                              // 名前
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    requests[index].uname,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "@${requests[index].uid}",
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                      //FIXME ここの送信済みを右に寄せる
                                      Text(
                                        '送信済み',
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // 削除ボタン
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () async {
                                  await DeleteFriendRequest()
                                      .deleteFriendRequest(
                                          requests[index].uid, userData.uid);
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
              onRefresh: _fetchFriends,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Ensure it can always scroll
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight, // Make sure the box fills the available height
                      ),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Spacer(flex: 1),
                                Icon(
                                  Icons.no_accounts,
                                  size: 35,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '表示できる情報がありません',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ),
                                Spacer(flex: 1),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
      ],
    );
  }

  Column Friends(List<FriendInformation> friends) {
    List<FriendInformation> filteredFriends = friends.where((friend) {
      return friend.uname
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
    }).toList();

    return Column(children: [
      SizedBox(height: SizeConfig.blockSizeVertical! * 2),
      if (friends.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              hintText: '検索',
              prefixIcon: const Icon(Icons.search, size: 20.0),
              fillColor: GlobalColor.Unselected,
              filled: true,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {}); // Refresh the widget to update UI
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {}); // Refresh the widget to apply the filter
            },
          ),
        ),
      const SizedBox(height: 10),
      if (filteredFriends.isNotEmpty)
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchFriends, // The function to reload friends
            child: ListView.builder(
              itemCount: filteredFriends.length,
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
                                  "https://calendar-files.woody1227.com/user_icon/${filteredFriends[index].uicon}"),
                            ),
                            SizedBox(
                                width: SizeConfig.blockSizeHorizontal! * 3),
                            // 名前
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friends[index].uname,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                Text(
                                  "@${friends[index].uid}",
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FriendProfile(friend: filteredFriends[index]),
                      ),
                    ).then((value) => () {
                          _fetchFriends();
                          _fetchReceivedRequests();
                          setState(() {});
                        });
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
                physics: const AlwaysScrollableScrollPhysics(), // Ensure it can always scroll
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight, // Make sure the box fills the available height
                  ),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Spacer(flex: 1),
                            Icon(
                              Icons.no_accounts,
                              size: 35,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '表示できる情報がありません',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                            Spacer(flex: 1),
                          ],
                        ),
                      ],
                    ),
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
