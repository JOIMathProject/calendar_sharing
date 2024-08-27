import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as global_colors;
import 'package:googleapis/script/v1.dart';
import 'package:provider/provider.dart';
import 'package:calendar_sharing/services/UserData.dart';
import '../setting/color.dart' as GlobalColor;

class ContentsSetting extends StatefulWidget {
  final String? groupId;
  ContentsSetting({required this.groupId});

  @override
  _ContentsSettingState createState() => _ContentsSettingState();
}

class _ContentsSettingState extends State<ContentsSetting> {
  String title = '';
  TextStyle bigFont = TextStyle(fontSize: 20);
  List<MyContentsInformation> calendars = [];
  List<UserInformation> users = [];  // List to store users
  String selectedIcon = 'default_icon.png';  // Placeholder for icon
  MyContentsInformation? selectedContent; // Allow selectedContent to be nullable

  @override
  void initState() {
    super.initState();
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getMyContents(uid!);
    _getGroupUsers(); // Load existing group users
  }

  Future<void> _getMyContents(String uid) async {
    calendars = await GetMyContents().getMyContents(uid);
    calendars.insert(0, MyContentsInformation(cid: '', cname: 'None')); // Add 'None' to the list
    selectedContent = await _getCurrentUserContent(widget.groupId!,uid); // Set default to current user content
    setState(() {}); // Trigger a rebuild once the content is loaded
  }

  Future<MyContentsInformation?> _getCurrentUserContent(String gid, String uid) async {
    List<ContentsInformation>? contents = await GetContentInGroup().getContentInGroup(gid);
    if (contents?.isNotEmpty == true) {
      // Find the content in calendars with matching uid
      return calendars.firstWhere(
            (content) => contents!.any((groupContent) => groupContent.uid == uid && content.cid == groupContent.cid),
        orElse: () => calendars[0], // Return 'None' if no match is found
      );
    }
    return calendars[0];
  }


  Future<void> _getGroupUsers() async {
    users = await GetUserInGroup().getUserInGroup(widget.groupId!);
    setState(() {});
  }

  Future<void> _changeGroupName(String gname) async {
    await UpdateGroupName().updateGroupName(widget.groupId, gname);
    setState(() {});
  }

  Future<void> _changeGroupIcon(String gicon) async {
    await UpdateGroupName().updateGroupName(widget.groupId, gicon);
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
    _getGroupUsers(); // Refresh the user list
  }

  Future<void> _removeUserFromGroup(String gid, String Removeuid) async {
    await DeleteUserFromGroup().deleteUserFromGroup(gid, Removeuid);
    _getGroupUsers(); // Refresh the user list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('設定', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(hintText: 'グループ名'),
              onChanged: (String value) {
                setState(() {
                  title = value;
                });
              },
              style: TextStyle(fontSize: 25),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _changeGroupName(title);
              },
              child: Text('グループ名を変更'),
            ),
            Text('ユーザー', style: bigFont),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(users[index].uname),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _removeUserFromGroup(widget.groupId!, users[index].uid);
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement logic to add user
              },
              child: Text('ユーザーを追加'),
            ),
            SizedBox(height: 20),
            Text("コンテンツを選択", style: bigFont),
            if (calendars.isNotEmpty)
              DropdownButton<MyContentsInformation>(
                value: selectedContent,
                items: calendars.map((MyContentsInformation content) {
                  return DropdownMenuItem<MyContentsInformation>(
                    value: content,
                    child: Text(content.cname),
                  );
                }).toList(),
                onChanged: (MyContentsInformation? newValue) async {
                  if (newValue != null) {
                    if (selectedContent?.cid != '') {
                      await _removeContentFromGroup(widget.groupId!, selectedContent!.cid);
                    }
                    setState(() {
                      selectedContent = newValue;
                    });
                    if (newValue.cname != 'None') {
                      await _addContentToGroup(widget.groupId!, newValue.cid);
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
