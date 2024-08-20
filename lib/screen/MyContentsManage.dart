import 'package:calendar_sharing/screen/createContents.dart';
import 'package:calendar_sharing/screen/Content.dart';
import 'package:calendar_sharing/screen/createMyContent.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import 'MyContent.dart';

class MyContentsManage extends StatefulWidget {
  @override
  _MyContentsManageState createState() => _MyContentsManageState();
}

List<MyContentsInformation> contents = [];

class _MyContentsManageState extends State<MyContentsManage> {
  @override
  void initState() {
    super.initState();
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getMyContents(uid!);
  }

  Future<void> _getMyContents(String uid) async {
    contents = await GetMyContents().getMyContents(uid);
    setState(() {}); // Trigger a rebuild once the content is loaded
  }

  Future<void> _reloadContents() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    if (uid != null) {
      await _getMyContents(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Contents'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit_calendar),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) =>  CreateMyContents()));
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadContents, // The function that will be called on pull-to-refresh
              child: ListView.builder(
                itemCount: contents.length, // Add this line
                itemBuilder: (context, index) {
                  if (contents.isNotEmpty) { // Check if contents is not empty
                    return ListTile(
                      title: Text(contents[index].cname),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyContent(
                                  cid: contents[index].cid,
                                )
                            )
                        );
                      },
                    );
                  } else {
                    return Center(child: CircularProgressIndicator()); // Show a loading spinner if contents is empty
                  }
                },
              )
            ),
          ),
        ],
      ),
    );
  }
}
