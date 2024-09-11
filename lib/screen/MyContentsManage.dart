import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import 'MyContent.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'createMyContent.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:calendar_sharing/screen/MyContentSetting.dart';

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
    contents = Provider.of<UserData>(context, listen: false).MyContents;
    _getMyContents(uid!);
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
      }
      _getMyContents(uid!);
    });
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

  Future<void> _deleteContent(String uid, String cid) async {
    await DeleteMyContents().deleteMyContents(uid, cid);
    _reloadContents(); // Refresh the contents after deletion
  }

  void _showDeleteConfirmationDialog(BuildContext context, String uid, String cid, String cname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('マイコンテンツを削除'),
          content: Text('本当にマイコンテンツ「$cname」を削除しますか? この操作は取り消せません。'),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
                _reloadContents(); // Reload contents if deletion is canceled
              },
            ),
            TextButton(
              child: Text('削除', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await _deleteContent(uid, cid);
                print('deleted');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「$cname」を削除しました')),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadContents,
              child:
              ListView.builder(
                itemCount: contents.length,
                itemBuilder: (context, index) {
                  if (contents.isNotEmpty) {
                    return Dismissible(
                      key: Key(contents[index].cid),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        // Handle the deletion logic
                        String? uid = Provider.of<UserData>(context, listen: false).uid;
                        _showDeleteConfirmationDialog(context, uid!, contents[index].cid, contents[index].cname);
                        setState(() {
                          contents.removeAt(index); // Immediately remove the item from the list
                        });
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      child: ListTile(
                        title: Text(contents[index].cname),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyContentSetting(
                                  cid: contents[index].cid,
                                  contentsName: contents[index].cname,
                                ),
                              ),
                            ).then((value) => _reloadContents());
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyContent(
                                cid: contents[index].cid,
                                contentsName: contents[index].cname,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return Center(
                      child: Text('コンテンツが見つかりませんでした'),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateMyContents())).then(
              (value) => _reloadContents()
          );
        },
        child: Icon(Icons.add, color: GlobalColor.SubCol),
        backgroundColor: GlobalColor.MainCol,
      ),
    );
  }
}
