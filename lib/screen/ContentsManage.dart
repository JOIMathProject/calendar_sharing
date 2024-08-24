import 'package:calendar_sharing/screen/createContents.dart';
import 'package:calendar_sharing/screen/Content.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';

class ContentsManage extends StatefulWidget {
  @override
  _ContentsManageState createState() => _ContentsManageState();
}

List<GroupInformation> contents = [];

class _ContentsManageState extends State<ContentsManage> {
  String currentLabel = '全て';

  @override
  void initState() {
    super.initState();
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getGroupContents(uid!);
  }

  Future<void> _getGroupContents(String uid) async {
    contents = await GetGroupInfo().getGroupInfo(uid);
    setState(() {}); // Trigger a rebuild once the content is loaded
  }

  Future<void> _reloadContents() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    if (uid != null) {
      await _getGroupContents(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('コンテンツ管理'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateContents()));
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <String>['全て', '個人', 'グループ']
                  .map((String value) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentLabel = value;
                    });
                  },
                  child: Text(value),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentLabel == value ? Colors.blue : Colors.grey,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadContents, // The function that will be called on pull-to-refresh
              child: ListView.builder(
                itemCount: _filteredContents().length,
                itemBuilder: (context, index) {
                  var filteredContents = _filteredContents();
                  return ListTile(
                    leading: CircleAvatar(
                      child: Image.network(
                          "https://calendar-files.woody1227.com/user_icon/${filteredContents[index].gicon}"),
                      backgroundColor: Colors.blue,
                    ),
                    title: Text(filteredContents[index].gname),
                    subtitle: Text('最後のメッセージ...'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('12:34 PM'),
                        IconButton(
                          icon: Icon(Icons.chat, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Home(
                                  groupId: filteredContents[index].gid,
                                  groupName: filteredContents[index].gname,
                                  startOnChatScreen: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      GoogleSignIn? gUser =
                          Provider.of<UserData>(context, listen: false).googleUser;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Home(
                                groupId: filteredContents[index].gid,
                                groupName: filteredContents[index].gname,
                                startOnChatScreen: false,
                              )));
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<GroupInformation> _filteredContents() {
    if (currentLabel == '個人') {
      return contents.where((content) => content.is_friends == '1').toList();
    } else if (currentLabel == 'グループ') {
      return contents.where((content) => content.is_friends == '0').toList();
    } else {
      return contents; // Show all contents if "All" is selected
    }
  }
}
