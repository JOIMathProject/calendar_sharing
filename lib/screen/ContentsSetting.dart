import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
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
  List<UserInformation> users = [];
  String selectedIcon = 'default_icon.png';
  MyContentsInformation? selectedContent;

  @override
  void initState() {
    super.initState();
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getMyContents(uid!);
    _getGroupUsers();
  }

  Future<void> _getMyContents(String uid) async {
    calendars = await GetMyContents().getMyContents(uid);
    calendars.insert(0, MyContentsInformation(cid: '', cname: 'None'));
    selectedContent = await _getCurrentUserContent(widget.groupId!, uid);
    setState(() {});
  }

  Future<MyContentsInformation?> _getCurrentUserContent(String gid, String uid) async {
    List<ContentsInformation>? contents = await GetContentInGroup().getContentInGroup(gid);
    if (contents?.isNotEmpty == true) {
      return calendars.firstWhere(
            (content) => contents!.any((groupContent) => groupContent.uid == uid && content.cid == groupContent.cid),
        orElse: () => calendars[0],
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
    _getGroupUsers();
  }

  Future<void> _removeUserFromGroup(String gid, String Removeuid) async {
    await DeleteUserFromGroup().deleteUserFromGroup(gid, Removeuid);
    _getGroupUsers();
  }

  Future<void> _showRemoveUserDialog(String uid, String uname) async {
    bool shouldRemove = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove User'),
          content: Text('Are you sure you want to remove $uname from the group?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Remove'),
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

  @override
  Widget build(BuildContext context) {
    String? currentUserUid = Provider.of<UserData>(context, listen: false).uid;

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
                // Implement logic to add user
              },
              child: Text('ユーザーを追加'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _removeUserFromGroup(widget.groupId!, currentUserUid!);
                Navigator.of(context).pop(); // Go back to the previous screen
              },
              child: Text('グループを離れる'),
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
