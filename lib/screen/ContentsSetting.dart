import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as global_colors;
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
  String cid = '';
  String selectedIcon = 'default_icon.png';  // Placeholder for icon
  String? selectedContent; // Allow selectedContent to be nullable

  @override
  void initState() {
    super.initState();
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getMyContents(uid!);
    //print calendars
    _getGroupUsers(); // Load existing group users
  }

  Future<void> _getMyContents(String uid) async {
    calendars = await GetMyContents().getMyContents(uid);
    if (calendars.isNotEmpty) {
      selectedContent = calendars[0].cname; // Set default selected value to first item
    }
    setState(() {}); // Trigger a rebuild once the content is loaded
  }

  Future<void> _getGroupUsers() async {
    print(widget.groupId!);
    users = await GetUserInGroup().getUserInGroup(widget.groupId!); // Fetch users
    print('hey');
    print(users.length);
    setState(() {}); // Trigger a rebuild
  }

  Future<void> _changeGroupName(String gname) async {
    await UpdateGroupName().updateGroupName(widget.groupId, gname);
  }

  Future<void> _changeGroupIcon(String gicon) async {
    await UpdateGroupName().updateGroupName(widget.groupId, gicon);
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
              DropdownButton<String>(
                value: selectedContent,
                items: calendars.map((MyContentsInformation content) {
                  return DropdownMenuItem<String>(
                    value: content.cname,
                    child: Text(content.cname),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedContent = newValue!;
                  });
                  _addContentToGroup(widget.groupId!, selectedContent!);
                },
              ),
          ],
        ),
      ),
    );
  }
}
