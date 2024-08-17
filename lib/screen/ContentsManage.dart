import 'package:calendar_sharing/screen/createContents.dart';
import 'package:calendar_sharing/screen/Content.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:provider/provider.dart';

import '../services/UserData.dart';


class ContentsManage extends StatefulWidget {
  @override
  _ContentsManageState createState() => _ContentsManageState();
}
List<GroupInformation> contents = [];
Future<void> _getGroupContents(String uid) async {
  contents = await GetGroupInfo().getGroupInfo(uid);
}
class _ContentsManageState extends State<ContentsManage> {
  String currentLabel = 'All';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contents Manage'),
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
              children: <String>['All', 'Personal', 'Group']
                  .map((String value) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentLabel = value;
                      // Handle your logic here for content selection
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
            child: ListView.builder(
              itemCount: currentLabel == 'All' ? contents.length : contents.where((content) => content.is_friends == currentLabel).length,
              itemBuilder: (context, index) {
                var filteredContents = currentLabel == 'All' ? contents : contents.where((content) => content.is_friends == currentLabel).toList();
                return ListTile(
                  leading: CircleAvatar(
                    child: Image.network("https://calendar-files.woody1227.com/user_icon/${filteredContents[index].gicon}"), // Display the icon
                    backgroundColor: Colors.blue, // Set the background color of the avatar
                  ),
                  title: Text(filteredContents[index].gname), // Display the name of the content
                  subtitle: Text('Last message...'), // Display the last message or other details
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('12:34 PM'), // Display the time of the last message
                      Icon(Icons.check_circle, color: Colors.blue), // Display the message status icon
                    ],
                  ),
                  onTap: () {
                    GoogleSignIn? gUser = Provider.of<UserData>(context, listen: false).googleUser;
                    print(gUser?.currentUser?.id);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Home(groupId: filteredContents[index].gid,)));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
