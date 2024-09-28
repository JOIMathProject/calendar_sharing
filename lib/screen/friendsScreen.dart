import 'package:calendar_sharing/screen/addFriendBluetooth.dart';
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
import 'dart:async';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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
    _reload();
  }

  void _reload() {
    //3秒ごとに
    Timer.periodic(
      const Duration(seconds: 3),
      (timer) async{
        await _fetchFriends();
        await _fetchReceivedRequests();
        setState(() {});
        if (!mounted) {
          timer.cancel();
        }
      },
    );
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
      floatingActionButton: SpeedDial(
        icon: Icons.person_add,
        activeIcon: Icons.close,
        backgroundColor: GlobalColor.MainCol,
        foregroundColor: GlobalColor.SubCol,
        activeBackgroundColor: GlobalColor.MainCol,
        activeForegroundColor: GlobalColor.SubCol,
        buttonSize: Size(56.0, 56.0),
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => print('OPENING DIAL'),
        onClose: () => print('DIAL CLOSED'),
        elevation: 8.0,
        shape: CircleBorder(),
        children: [
          SpeedDialChild(
            child: Icon(Icons.camera_alt),
            backgroundColor: GlobalColor.MainCol,
            foregroundColor: GlobalColor.SubCol,
            label: 'スキャンで追加',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () {
              // Add camera functionality here
              print('Camera Add Tapped');
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.text_fields),
            backgroundColor: GlobalColor.MainCol,
            foregroundColor: GlobalColor.SubCol,
            label: 'UIDから追加',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFriend()),
              ).then((_) {
                _fetchFriends();
                _fetchReceivedRequests();
                setState(() {});
              });
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.bluetooth),
            backgroundColor: GlobalColor.MainCol,
            foregroundColor: GlobalColor.SubCol,
            label: 'Bluetoothで追加',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFriendNearby(myUid: Provider.of<UserData>(context).uid!),
              )
              );
            },
          ),
        ],
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
              child: ListView(
                children: [
                  requests.where((req) => req.isReceived).length == 0
                      ? Container()
                      :
                      // Received Requests Section
                      Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            "受信リクエスト (${requests.where((req) => req.isReceived).length})",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                  ListView.builder(
                    shrinkWrap:
                        true, // Makes the ListView take only the space it needs
                    physics:
                        NeverScrollableScrollPhysics(), // Prevents nested scrolling
                    itemCount: requests.where((req) => req.isReceived).length,
                    itemBuilder: (context, index) {
                      var receivedRequests =
                          requests.where((req) => req.isReceived).toList();
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Icon
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                      "https://calendar-files.woody1227.com/user_icon/${receivedRequests[index].uicon}"),
                                ),
                                SizedBox(
                                    width: SizeConfig.blockSizeHorizontal! * 3),
                                // Name
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      receivedRequests[index].uname,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "@${receivedRequests[index].uid}",
                                          style: TextStyle(
                                            fontSize: 17,
                                            color:
                                                Colors.black.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // Approval and rejection buttons
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () async {
                                    await AcceptFriendRequest()
                                        .acceptFriendRequest(userData.uid,
                                            receivedRequests[index].uid);
                                    _fetchReceivedRequests();
                                    _fetchFriends();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () async {
                                    await DeleteFriendRequest()
                                        .deleteFriendRequest(userData.uid,
                                            receivedRequests[index].uid);
                                    _fetchReceivedRequests();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Divider Section
                  requests.where((req) => req.isReceived).length == 0
                      ? Container()
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(),
                        ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: requests.where((req) => !req.isReceived).length == 0
                        ? Container()
                        : Text(
                            "送信リクエスト (${requests.where((req) => !req.isReceived).length})",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                  // Sent Requests Section
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        NeverScrollableScrollPhysics(), // Prevents nested scrolling
                    itemCount: requests.where((req) => !req.isReceived).length,
                    itemBuilder: (context, index) {
                      var sentRequests =
                          requests.where((req) => !req.isReceived).toList();
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Icon
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                      "https://calendar-files.woody1227.com/user_icon/${sentRequests[index].uicon}"),
                                ),
                                SizedBox(
                                    width: SizeConfig.blockSizeHorizontal! * 3),
                                // Name
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sentRequests[index].uname,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "@${sentRequests[index].uid}",
                                          style: TextStyle(
                                            fontSize: 17,
                                            color:
                                                Colors.black.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () async {
                                    await DeleteFriendRequest()
                                        .deleteFriendRequest(
                                            sentRequests[index].uid,
                                            userData.uid);
                                    _fetchReceivedRequests();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Ensure it can always scroll
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints
                            .maxHeight, // Make sure the box fills the available height
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
            style: TextStyle(color: GlobalColor.SubCol),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              hintText: '検索',
              hintStyle: TextStyle(color: GlobalColor.SubCol),
              fillColor: GlobalColor.searchBarCol,
              prefixIcon: const Icon(Icons.search, size: 20.0),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FriendProfile(friend: filteredFriends[index]),
                      ),
                    ).then((value) {
                      _fetchFriends();
                      _fetchReceivedRequests();
                      setState(() {});
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: GlobalColor.ItemCol,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey, // Bottom border color
                          width: 0.2, // Bottom border width
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0), // Inner padding
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
                            SizedBox(width: SizeConfig.blockSizeHorizontal! * 3),
                            // 名前
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filteredFriends[index].uname, // Changed from friends[index] to filteredFriends[index]
                                  style: const TextStyle(fontSize: 22),
                                ),
                                Text(
                                  "@${filteredFriends[index].uid}", // Changed from friends[index] to filteredFriends[index]
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Ensure it can always scroll
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints
                          .maxHeight, // Make sure the box fills the available height
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
