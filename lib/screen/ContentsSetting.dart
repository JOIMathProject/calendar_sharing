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
  bool isEditingGName = false;
  TextEditingController gnameController = TextEditingController();
  GroupDetail _groupDetail = GroupDetail(
    gid: '',
    gname: '',
    gicon: '',
    is_friends: '0',
  );
  @override
  void initState() {
    super.initState();
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getMyContents(uid!);
    _getGroupUsers();
    _getGroupDetail();
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
    setState(() {
      _groupDetail.gname = gname; // Update the local group detail name
      gnameController.text = gname; // Update the text controller
      isEditingGName = false; // Exit edit mode
    });
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
            Text('設定', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            buildProfileField(
              context,
              label: 'グループ名',
              controller: gnameController,
              isEditing: isEditingGName,
              onEditToggle: () {
                setState(() {
                  isEditingGName = !isEditingGName;
                });
              },
              onSave: () async {
                if (gnameController.text.isNotEmpty &&
                    gnameController.text != _groupDetail.gname) {
                  _changeGroupName(gnameController.text);
                  setState(() {
                    isEditingGName = false;
                  });
                }
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
                // Implement logic to add user
              },
              child: Text('ユーザーを追加'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _removeUserFromGroup(widget.groupId!, currentUserUid!);
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pop();
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
  Widget buildProfileField(BuildContext context,
      {required String label,
        required TextEditingController controller,
        required bool isEditing,
        required VoidCallback onEditToggle,
        required VoidCallback onSave}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isEditing
              ? Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: label,
              ),
            ),
          )
              : Text('$label: ${controller.text}', style: TextStyle(fontSize: 18)),
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: isEditing ? onSave : onEditToggle,
          ),
        ],
      ),
    );
  }
}
