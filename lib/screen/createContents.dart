import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/APIcalls.dart';
import '../services/UserData.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

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
  String base64Image = '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';
  Uint8List _image = base64Decode('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');
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
  Future<String?> getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Read the image file as bytes
      final imageBytes = await File(pickedFile.path).readAsBytes();

      // Decode the image bytes
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return null; // Could not decode the image
      }

      // Correct the orientation if needed
      final rotatedImage = img.bakeOrientation(image);

      int width = rotatedImage.width;
      int height = rotatedImage.height;
      int squareSide = width < height ? width : height;

      int targetSize = squareSide < 256 ? squareSide : 256;

      int offsetX = (width - squareSide) ~/ 2;
      int offsetY = (height - squareSide) ~/ 2;
      final croppedImage = img.copyCrop(
        rotatedImage,
        x: offsetX,
        y: offsetY,
        width: squareSide,
        height: squareSide,
        radius: 0,
        antialias: true,
      );

      final resizedImage = img.copyResize(
        croppedImage,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.average,
      );

      final correctedBytes = img.encodeJpg(resizedImage);

      final base64String = base64Encode(correctedBytes);
      return base64String;
    }

    return null; // No image was picked
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
                      backgroundImage: Image.memory(_image).image,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          String? image = await getImageFromGallery();
                          if (image != null) {
                            base64Image = image;
                            print(base64Image);
                            setState(() {
                              _image = base64Decode(image);
                            });
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
      ),
      title: Text(friend.uname),
      trailing: Checkbox(
        value: isSelected,
        onChanged: onSelected,
        checkColor: GlobalColor.SubCol,
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GlobalColor.MainCol;
          }
          return null;
        }),
      ),
      onTap: () {
        // Toggle selection when the tile is tapped
        onSelected(!isSelected);
      },
    );
  }
}
