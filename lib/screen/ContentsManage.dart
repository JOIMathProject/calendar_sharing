import 'package:calendar_sharing/screen/createContents.dart';
import 'package:calendar_sharing/screen/home.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../services/UserData.dart';

class ContentsManage extends StatefulWidget {
  @override
  _ContentsManageState createState() => _ContentsManageState();
}
class Content {
  final String name;
  final String label;

  Content({required this.name, required this.label});
}
class _ContentsManageState extends State<ContentsManage> {
  // This is just a placeholder. Replace it with your actual list of contents.
  List<Content> contents = [
    Content(name: 'Content 1', label: 'Personal'),
    Content(name: 'Content 2', label: 'Group'),
    Content(name: 'Content 3', label: 'MyContents'),
  ];

  // This will hold the current selected label
  String currentLabel = 'All';

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
              children: <String>['All', 'Personal', 'Group', 'MyContents']
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
              itemCount: currentLabel == 'All' ? contents.length : contents.where((content) => content.label == currentLabel).length,
              itemBuilder: (context, index) {
                var filteredContents = currentLabel == 'All' ? contents : contents.where((content) => content.label == currentLabel).toList();
                return ElevatedButton(
                  onPressed: () {
                    GoogleSignIn? gUser = Provider.of<UserData>(context, listen: false).googleUser;
                    print(gUser?.currentUser?.id);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Home(gUser: gUser)));
                  },
                  child: Text(filteredContents[index].name), // Display the name of the content
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}