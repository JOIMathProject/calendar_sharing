import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as global_colors;
import 'package:provider/provider.dart';
import '../services/APIcalls.dart';
import '../services/UserData.dart';

class CreateContents extends StatefulWidget {
  @override
  _CreateContentsState createState() => _CreateContentsState();
}

class _CreateContentsState extends State<CreateContents> {
  String title = '';
  List<String> peoples = [];
  List<String> selectedFriends = [];
  List<FriendInformation> filteredFriends = [];
  TextStyle bigFont = TextStyle(fontSize: 20);

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      UserData userData = Provider.of<UserData>(context, listen: false);
      List<FriendInformation> friends = await GetFriends().getFriends(userData.uid);
      Provider.of<UserData>(context, listen: false).updateFriends(friends);
      setState(() {
        filteredFriends = friends;
      });
    } catch (e) {
      print("Error fetching friends: $e");
    }
  }

  void _filterFriends(String query) {
    UserData userData = Provider.of<UserData>(context, listen: false);
    List<FriendInformation> friends = userData.friends;
    setState(() {
      filteredFriends = friends.where((friend) {
        return friend.uname.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);
    List<FriendInformation> friends = userData.friends;

    return Scaffold(
      appBar: AppBar(
        title: Text('グループの作成'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '検索...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: _filterFriends,
            ),
          ),
          if (selectedFriends.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 8.0,
                children: selectedFriends.map((friendUid) {
                  final friend = friends.firstWhere((f) => f.uid == friendUid);
                  return Chip(
                    label: Text(friend.uname),
                    onDeleted: () {
                      setState(() {
                        selectedFriends.remove(friendUid);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                return FriendTile(
                  friend: filteredFriends[index],
                  isSelected: selectedFriends.contains(filteredFriends[index].uid),
                  onSelected: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        selectedFriends.add(filteredFriends[index].uid);
                      } else {
                        selectedFriends.remove(filteredFriends[index].uid);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                peoples = selectedFriends; // Add selected friends to peoples list
                // Implement the group creation logic here
              },
              child: Text('作成'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(100, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class FriendTile extends StatelessWidget {
  final FriendInformation friend;
  final bool isSelected;
  final ValueChanged<bool?> onSelected;

  const FriendTile({
    Key? key,
    required this.friend,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
            "https://calendar-files.woody1227.com/user_icon/" +
                friend.uicon),
        child: Text(friend.uname[0]), // Fallback to the first letter of their name
      ),
      title: Text(friend.uname),
      trailing: Checkbox(
        value: isSelected,
        onChanged: onSelected,
      ),
      onTap: () {
        // Toggle selection when the tile is tapped
        onSelected(!isSelected);
      },
    );
  }
}

