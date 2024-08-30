import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
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
  String gid = '';
  TextEditingController _groupTitleController = TextEditingController();
  TextEditingController _friendSearchController = TextEditingController();
  final imagePicker = ImagePicker();
  XFile currentImage = XFile('assets/images/default_group_icon.png');
  String base64Image = '';

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      UserData userData = Provider.of<UserData>(context, listen: false);
      List<FriendInformation> friends =
      await GetFriends().getFriends(userData.uid);
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

  Future<void> _createEmptyGroup(String gname, String gicon) async {
    gid = await CreateEmptyGroup().createEmptyGroup(gname, gicon);
    print('$gid');
  }

  Future<void> _addUserToGroup(String gid, String Adduid) async {
    await AddUserToGroup().addUserToGroup(gid, Adduid);
  }

  Future<XFile?> getImageFromGallery() async {
    return await imagePicker.pickImage(source: ImageSource.gallery);
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);
    List<FriendInformation> friends = userData.friends;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'グループの作成',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(File(currentImage.path)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          XFile? image = await getImageFromGallery();
                          if (image != null) {
                            List<int> imageBytes = await File(image.path).readAsBytesSync();
                            base64Image = base64Encode(imageBytes);
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          radius: 18,
                          child: Icon(Icons.edit, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20),
                Expanded(
                  child:

                  TextField(
                    controller: _groupTitleController,
                    decoration: InputDecoration(
                      hintText: 'グループタイトルを入力...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: GlobalColor.Unselected,
                      suffixIcon: title.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _groupTitleController.clear();
                          setState(() {
                            title = ''; // Clear the title value
                          });
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        title = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _friendSearchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '検索...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: GlobalColor.Unselected,
                suffixIcon: _friendSearchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _friendSearchController.clear();
                    _filterFriends(''); // Reset the filter when clearing text
                    setState(() {});  // Refresh the widget to update UI
                  },
                )
                    : null,
              ),
              onChanged: (text) {
                _filterFriends(text);
                setState(() {});  // Refresh the widget to apply changes
              },
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
                  isSelected:
                  selectedFriends.contains(filteredFriends[index].uid),
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
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  peoples =
                      selectedFriends; // Add selected friends to peoples list
                  _makeGroup(peoples, userData.uid!);
                  Navigator.pop(context);
                },
                child: Text('作成',
                    style: TextStyle(fontSize: 20, color: GlobalColor.SubCol)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _makeGroup(List<String> selectedFriends, String ownUid) async {
    if (title.isEmpty) {
      title = ownUid;
      for (var uid in selectedFriends) {
        title += ', ';
        title += uid;
      }
    }

    await _createEmptyGroup(title, base64Image); // Pass the selected icon
    await _addUserToGroup(gid, ownUid);
    for (var uid in selectedFriends) {
      await _addUserToGroup(gid, uid);
    }
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
            "https://calendar-files.woody1227.com/user_icon/" + friend.uicon),
        child:
        Text(friend.uname[0]), // Fallback to the first letter of their name
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
