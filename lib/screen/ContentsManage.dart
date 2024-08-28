import 'package:calendar_sharing/screen/createContents.dart';
import 'package:calendar_sharing/screen/Content.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:badges/badges.dart' as badge;

class ContentsManage extends StatefulWidget {
  @override
  _ContentsManageState createState() => _ContentsManageState();
}

List<GroupInformation> contents = [];

class _ContentsManageState extends State<ContentsManage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final timeFormat = DateFormat('HH:mm');
  final dateFormat = DateFormat('MM/dd');

  @override
  void initState() {
    super.initState();
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getGroupContents(uid!);
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getGroupContents(String uid) async {
    contents = await GetGroupInfo().getGroupInfo(uid);
    setState(() {});
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
        title: Text(
          'Sando',
          style: TextStyle(
            color: GlobalColor.MainCol,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',
          ),
        ),
        backgroundColor: GlobalColor.SubCol,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                hintText: '検索',
                prefixIcon: Icon(Icons.search, size: 20.0),
                fillColor: GlobalColor.Unselected,
                filled: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'すべて'),
              Tab(text: 'フレンド'),
              Tab(text: 'グループ'),
            ],
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: GlobalColor.MainCol,
                  width: 3.0,
                ),
              ),
            ),
            labelStyle: TextStyle(fontSize: 16.0),
            labelColor: GlobalColor.MainCol,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContentList(_filteredContents()), // All
                _buildContentList(_filteredContents(isPersonal: true)), // Personal
                _buildContentList(_filteredContents(isGroup: true)), // Group
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateContents()));
        },
        child: Icon(Icons.add, color: GlobalColor.SubCol),
        backgroundColor: GlobalColor.MainCol,
      ),
    );
  }

  List<GroupInformation> _filteredContents({bool isPersonal = false, bool isGroup = false}) {
    List<GroupInformation> filteredContents;
    if (isPersonal) {
      filteredContents = contents.where((content) => content.is_friends == '1').toList();
    } else if (isGroup) {
      filteredContents = contents.where((content) => content.is_friends == '0').toList();
    } else {
      filteredContents = contents;
    }

    if (_searchQuery.isNotEmpty) {
      filteredContents = filteredContents
          .where((content) => content.gname.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    // Sort by latest message time
    filteredContents.sort((a, b) => b.latest_message_time.compareTo(a.latest_message_time));
    return filteredContents;
  }

  Widget _buildContentList(List<GroupInformation>? filteredContents) {
    return RefreshIndicator(
      onRefresh: _reloadContents,
      child: ListView.builder(
        itemCount: filteredContents?.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                filteredContents?[index].is_friends == '1'
                    ? "https://calendar-files.woody1227.com/user_icon/${filteredContents?[index].gicon}"
                    : "https://calendar-files.woody1227.com/group_icon/${filteredContents?[index].gicon}",
              ),
              backgroundColor: Colors.blue,
            ),
            title: Text(filteredContents![index].gname),
            subtitle: Text(filteredContents[index].latest_message),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                badge.Badge(
                  showBadge: filteredContents[index].unread_messages > 0,
                  badgeContent: Text(
                    filteredContents[index].unread_messages.toString(),
                    style: TextStyle(color: GlobalColor.SubCol),
                  ),
                ),
                SizedBox(width: 10.0),
                Text(
                  //今日なら時刻、それ以外なら日付
                  filteredContents[index].latest_message_time.day == DateTime.now().day &&
                          filteredContents[index].latest_message_time.month == DateTime.now().month &&
                          filteredContents[index].latest_message_time.year == DateTime.now().year
                      ? timeFormat.format(filteredContents[index].latest_message_time)
                      : dateFormat.format(filteredContents[index].latest_message_time),
                ),
                IconButton(
                  icon: Icon(Icons.chat, color: GlobalColor.Unselected),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(
                          groupId: filteredContents?[index].gid,
                          groupName: filteredContents?[index].gname,
                          startOnChatScreen: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              GoogleSignIn? gUser = Provider.of<UserData>(context, listen: false).googleUser;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(
                    groupId: filteredContents?[index].gid,
                    groupName: filteredContents?[index].gname,
                    startOnChatScreen: false,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
