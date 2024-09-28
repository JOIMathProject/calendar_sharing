import 'dart:async';

import 'package:calendar_sharing/screen/createContents.dart';
import 'package:calendar_sharing/screen/Content.dart';
import 'package:calendar_sharing/screen/mainScreen.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:badges/badges.dart' as badge;

class ContentsManage extends StatefulWidget {
  List<GroupInformation> contents = [];
  ContentsManage({
    super.key,
    required this.contents,
  });
  @override
  _ContentsManageState createState() => _ContentsManageState();
}

class _ContentsManageState extends State<ContentsManage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final timeFormat = DateFormat('HH:mm');
  final dateFormat = DateFormat('MM/dd');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool isToday(DateTime date) {
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 9));
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: GlobalColor.SubCol),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                hintText: '検索',
                hintStyle: TextStyle(color: GlobalColor.SubCol),
                prefixIcon: Icon(Icons.search, size: 20.0),
                fillColor: GlobalColor.searchBarCol,
                filled: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
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
                    dividerColor: GlobalColor.Unselected,
                    labelColor: GlobalColor.MainCol,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildContentList(_filteredContents()),
                        _buildContentList(_filteredContents(isPersonal: true)),
                        _buildContentList(_filteredContents(isGroup: true)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CreateContents()));
        },
        backgroundColor: GlobalColor.MainCol,
        child: Icon(Icons.group_add, color: GlobalColor.SubCol),
      ),
    );
  }

  List<GroupInformation> _filteredContents(
      {bool isPersonal = false, bool isGroup = false}) {
    List<GroupInformation> filteredContents;
    if (isPersonal) {
      filteredContents = widget.contents
          .where((content) => content.is_friends == '1')
          .toList();
    } else if (isGroup) {
      filteredContents = widget.contents
          .where((content) => content.is_friends == '0')
          .toList();
    } else {
      filteredContents = widget.contents;
    }

    if (_searchQuery.isNotEmpty) {
      filteredContents = filteredContents
          .where((content) =>
              content.gname.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    // Sort by latest message time
    filteredContents
        .sort((a, b) => b.latest_message_time.compareTo(a.latest_message_time));
    return filteredContents;
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

  Widget _buildContentList(List<GroupInformation>? filteredContents) {
    return RefreshIndicator(
      onRefresh: _reloadContents,
      child: filteredContents!.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics:
                      AlwaysScrollableScrollPhysics(), // Ensures the refresh indicator can always be triggered
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints
                          .maxHeight, // Make sure the box fills the available height
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Center the content within the Row
                              children: [
                                Icon(
                                  Icons.group_off_sharp,
                                  size: 35,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '表示できる情報がありません',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : ListView.builder(
        itemCount: filteredContents.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(
                    groupId: filteredContents[index].gid,
                    groupName: filteredContents[index].gname,
                    startOnChatScreen: false,
                    firstVisit: filteredContents[index].is_opened == '0',
                    is_frined: filteredContents[index].is_friends == '1',
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: GlobalColor.ItemCol,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey, // Border color
                    width: 0.2, // Border width
                  ),
                ),
              ),
              padding: const EdgeInsets.all(10.0), // Inner padding
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    filteredContents[index].is_friends == '1'
                        ? "https://calendar-files.woody1227.com/user_icon/${filteredContents[index].gicon}"
                        : "https://calendar-files.woody1227.com/group_icon/${filteredContents[index].gicon}",
                  ),
                  backgroundColor: GlobalColor.Unselected,
                ),
                title: Text(filteredContents[index].gname),
                subtitle: Text(
                  filteredContents[index].latest_message.length > 15
                      ? '${filteredContents[index].latest_message.substring(0, 15)}...'
                      : filteredContents[index].latest_message,
                ),
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
                    const SizedBox(width: 10.0),
                    Text(
                      // Today: show time; Otherwise: show date
                      isToday(filteredContents[index].latest_message_time)
                          ? timeFormat.format(filteredContents[index].latest_message_time)
                          : dateFormat.format(filteredContents[index].latest_message_time),
                    ),
                    IconButton(
                      icon: Icon(Icons.chat, color: Colors.black54),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Home(
                              groupId: filteredContents[index].gid,
                              groupName: filteredContents[index].gname,
                              firstVisit: filteredContents[index].is_opened == '0',
                              startOnChatScreen: true,
                              is_frined: filteredContents[index].is_friends == '1',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

    );
  }
}
