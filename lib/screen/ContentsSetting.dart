import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/calendar/v3.dart' as ggl;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:image/image.dart' as img;

class ContentsSetting extends StatefulWidget {
  final String? groupId;
  final MyContentsInformation? usedCalendar;
  ContentsSetting({required this.groupId, required this.usedCalendar});

  @override
  _ContentsSettingState createState() => _ContentsSettingState();
}

class _ContentsSettingState extends State<ContentsSetting> {
  String title = '';
  TextStyle bigFont = TextStyle(fontSize: 20);
  List<MyContentsInformation> _MyContents = [];
  List<CalendarInformation> _MyCalendar = [];
  List<UserInformation> users = [];
  String selectedIcon = '';
  MyContentsInformation? selectedContent;
  CalendarInformation? selectedCalendar;
  bool isEditingGName = false;
  TextEditingController gnameController = TextEditingController();
  final imagePicker = ImagePicker();
  List<FriendInformation> _friends = [];
  GroupDetail _groupDetail = GroupDetail(
    gid: '',
    gname: '',
    gicon: '',
    is_friends: '0',
  );
  String? uid;
  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserData>(context, listen: false).uid;
    _getMyContents(uid!);
    _getGroupUsers();
    _getGroupDetail();
    _friends = Provider.of<UserData>(context, listen: false).friends;
    gnameController.text = _groupDetail.gname;
  }

  Future<void> _addCalendarToGroup(
      String? gid, String? uid, String? calendar_id) async {
    await SetGroupPrimaryCalendar()
        .setGroupPrimaryCalendar(gid, uid, calendar_id);
  }

  Future<void> _removeCalendarFromGroup(
      String? gid, String? uid, String? calendar_id) async {
    await DeleteGroupPrimaryCalendar()
        .deleteGroupPrimaryCalendar(gid, uid, calendar_id);
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

      // Resize the image to 256x256
      final resizedImage = img.copyResize(image, width: 256, height: 256);

      // Correct the orientation if needed
      final rotatedImage = img.bakeOrientation(resizedImage);

      // Encode the corrected image back into bytes
      final correctedBytes = img.encodeJpg(rotatedImage);

      // Convert the bytes to a base64 string
      final base64String = base64Encode(correctedBytes);
      return base64String;
    }

    return null; // No image was picked
  }
  Future<void> _getMyContents(String uid) async {
    _MyCalendar = Provider.of<UserData>(context, listen: false).MyCalendar;
    _MyContents = Provider.of<UserData>(context, listen: false).MyContents;
    selectedContent = await _getCurrentUserContent(widget.groupId!, uid);
    String selectedCalId = await GetGroupPrimaryCalendar().getGroupPrimaryCalendar(widget.groupId,uid);
    selectedCalendar = _MyCalendar.firstWhere(
      (element) => element.calendar_id == selectedCalId,
      orElse: () => _MyCalendar[0],
    );
    setState(() {});
  }

  Future<MyContentsInformation?> _getCurrentUserContent(
      String gid, String uid) async {
    List<ContentsInformation>? contents =
        await GetContentInGroup().getContentInGroup(gid);
    if (contents?.isNotEmpty == true) {
      return _MyContents.firstWhere(
        (content) => contents!.any((groupContent) =>
            groupContent.uid == uid && content.cid == groupContent.cid),
        orElse: () => _MyContents[0],
      );
    }
    return _MyContents[0];
  }

  Future<void> _getGroupUsers() async {
    users = await GetUserInGroup().getUserInGroup(widget.groupId!);
    setState(() {});
  }

  Future<void> _changeGroupName(String gname) async {
    await UpdateGroupName().updateGroupName(widget.groupId, gname);
    setState(() {
      _groupDetail.gname = gname; // Update the local group detail name
      gnameController.text = gname; // Update the text controller
      isEditingGName = false; // Exit edit mode
    });
  }
  Future<void> _changeGroupIcon(String gicon) async {
    await UpdateGroupIcon().updateGroupIcon(widget.groupId, gicon);
    setState(() {});
  }

  Future<void> _addContentToGroup(String gid, String cid) async {
    await AddContentsToGroup().addContentsToGroup(gid, cid);
  }

  Future<void> _removeContentFromGroup(String gid, String cid) async {
    await RemoveContentsFromGroup().removeContentsFromGroup(gid, cid);
  }

  Future<void> _addUserToGroup(String gid, String Adduid) async {
    await AddUserToGroup().addUserToGroup(gid, Adduid);
    _getGroupUsers();
  }

  Future<void> _removeUserFromGroup(String gid, String Removeuid) async {
    await DeleteUserFromGroup().deleteUserFromGroup(gid, Removeuid);
    _getGroupUsers();
  }

  Future<void> _getGroupDetail() async {
    _groupDetail = await GetGroupDetail().getGroupDetail(widget.groupId);
  }

  Future<void> _showRemoveUserDialog(String uid, String uname) async {
    bool shouldRemove = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ユーザーを削除'),
          content: Text('$uname をグループから削除してよろしいですか?'),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('削除する'),
              onPressed: () {
                shouldRemove = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    if (shouldRemove) {
      await _removeUserFromGroup(widget.groupId!, uid);
    }
  }

  List<String> selectedFriends = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String? currentUserUid = Provider.of<UserData>(context, listen: false).uid;
    gnameController.text = _groupDetail.gname;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('設定',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                        "https://calendar-files.woody1227.com/group_icon/${_groupDetail.gicon}",
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      String? image = await getImageFromGallery();
                      if (image != null) {
                        _changeGroupIcon(image);
                        _getGroupDetail();
                        setState(() {}); // Refresh the widget to update UI
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
            buildProfileField(
              context,
              label: 'グループ名',
              controller: gnameController,
              isEditing: isEditingGName,
              restrictInput: false,
              onEditToggle: () {
                setState(() {
                  isEditingGName = !isEditingGName;
                });
              },
              onSave: () async {
                if (gnameController.text.isNotEmpty &&
                    gnameController.text != _groupDetail.gname) {
                  _changeGroupName(gnameController.text);
                }
                setState(() {
                  isEditingGName = false;
                });
              },
            ),
            Text('ユーザー', style: bigFont),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  String uid = users[index].uid;
                  return ListTile(
                    title: Text(users[index].uname),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: uid != currentUserUid
                          ? () => _showRemoveUserDialog(uid, users[index].uname)
                          : null, // Prevent self-deletion
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: GlobalColor.SubCol,
                  isScrollControlled: true, // Makes the BottomSheet larger
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return FractionallySizedBox(
                          heightFactor:
                              0.9, // Adjust the height of the BottomSheet
                          child: Column(
                            children: [
                              // White notch at the top
                              Container(
                                width: 50,
                                height: 5,
                                margin: EdgeInsets.only(top: 10, bottom: 10),
                                decoration: BoxDecoration(
                                  color: GlobalColor.MainCol,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _friends.length,
                                  itemBuilder: (context, index) {
                                    bool isSelected = selectedFriends
                                        .contains(_friends[index].uid);
                                    bool isUserAlreadyAdded = users.any(
                                        (user) =>
                                            user.uid == _friends[index].uid);

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          "https://calendar-files.woody1227.com/user_icon/${_friends[index].uicon}",
                                        ),
                                      ),
                                      title: Text(_friends[index].uname),
                                      trailing: Checkbox(
                                        value: isSelected,
                                        onChanged: isUserAlreadyAdded
                                            ? null
                                            : (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    selectedFriends.add(
                                                        _friends[index].uid);
                                                  } else {
                                                    selectedFriends.remove(
                                                        _friends[index].uid);
                                                  }
                                                });
                                              },
                                      ),
                                      onTap: isUserAlreadyAdded
                                          ? null
                                          : () {
                                              setState(() {
                                                if (isSelected) {
                                                  selectedFriends.remove(
                                                      _friends[index].uid);
                                                } else {
                                                  selectedFriends
                                                      .add(_friends[index].uid);
                                                }
                                              });
                                            },
                                      enabled:
                                          !isUserAlreadyAdded, // Disable tap if user already exists in users
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: 20.0), // Moves the button upward
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle the addition of selected friends
                                    for (String friendUid in selectedFriends) {
                                      _addUserToGroup(
                                          widget.groupId!, friendUid);
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: Text('選択したユーザーを追加',
                                      style:
                                          TextStyle(color: GlobalColor.SubCol)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
              child:
                  Text('ユーザーを追加', style: TextStyle(color: GlobalColor.SubCol)),
            ),
            SizedBox(height: 20),
            Text("コンテンツを選択", style: bigFont),
            if (_MyContents.isNotEmpty)
              DropdownButton<MyContentsInformation>(
                value: selectedContent,
                items: _MyContents.map((MyContentsInformation content) {
                  return DropdownMenuItem<MyContentsInformation>(
                    value: content,
                    child: Text(content.cname),
                  );
                }).toList(),
                onChanged: (MyContentsInformation? newValue) async {
                  if (newValue != null) {
                    if (selectedContent?.cid != '') {
                      await _removeContentFromGroup(
                          widget.groupId!, selectedContent!.cid);
                    }
                    setState(() {
                      selectedContent = newValue;
                    });
                    if (newValue.cname != 'None') {
                      await _addContentToGroup(widget.groupId!, newValue.cid);
                    }
                  }
                },
              ),SizedBox(height: 20),
            Text("カレンダーを選択", style: bigFont),
            if (_MyCalendar.isNotEmpty)
              DropdownButton<CalendarInformation>(
                value: selectedCalendar,
                items: _MyCalendar.map((CalendarInformation content) {
                  return DropdownMenuItem<CalendarInformation>(
                    value: content,
                    child: Text(content.summary),
                  );
                }).toList(),
                onChanged: (CalendarInformation? newValue) async {
                  if (newValue != null) {
                    if (selectedCalendar?.summary != '') {
                      await _removeCalendarFromGroup(widget.groupId, uid, selectedCalendar?.calendar_id);
                    }
                    setState(() {
                      selectedCalendar = newValue;
                    });
                    if (newValue.summary != 'None') {
                      //await _addContentToGroup(widget.groupId!, newValue.summary);
                      await _addCalendarToGroup(widget.groupId, uid, selectedCalendar?.calendar_id);
                    }
                  }
                },
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _removeUserFromGroup(widget.groupId!, currentUserUid!);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child:
                  Text('グループを離れる', style: TextStyle(color: GlobalColor.SubCol)),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildProfileField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required bool isEditing,
        required bool restrictInput, // New parameter to control input restriction
        required VoidCallback onEditToggle,
        required VoidCallback onSave,
      }) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isEditing
              ? Expanded(
            child: TextField(
              maxLength: 15,
              controller: controller,
              style: TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: label,
              ),
              inputFormatters: restrictInput
                  ? [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              ]
                  : [], // No restriction if restrictInput is false
            ),
          )
              : Text(
              label == 'ユーザーID'
                  ? '$label: @${controller.text}'
                  : '$label: ${controller.text}',
              style: TextStyle(fontSize: 18)),
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: isEditing ? onSave : onEditToggle,
          ),
        ],
      ),
    );
  }
}
