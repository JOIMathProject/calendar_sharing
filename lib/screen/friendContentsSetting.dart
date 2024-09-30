import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/calendar/v3.dart' as ggl;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:image/image.dart' as img;

class friendContentsSetting extends StatefulWidget {
  final String? groupId;
  final MyContentsInformation? usedCalendar;
  friendContentsSetting({required this.groupId, required this.usedCalendar});

  @override
  _friendContentsSettingState createState() => _friendContentsSettingState();
}

class _friendContentsSettingState extends State<friendContentsSetting> {
  String title = '';
  TextStyle bigFont = TextStyle(fontSize: 20);
  List<MyContentsInformation> _MyContents = [];
  List<CalendarInformation> _MyCalendar = [];
  List<UserInformation> users = [];
  String selectedIcon = '';
  MyContentsInformation? selectedContent;
  CalendarInformation? selectedCalendar;
  bool isEditingGName = false;
  TextEditingController gnameController = TextEditingController();
  final imagePicker = ImagePicker();
  List<FriendInformation> _friends = [];
  GroupDetail _groupDetail = GroupDetail(
    gid: '',
    gname: '',
    gicon: '',
    is_friends: '0',
  );
  String? uid;
  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserData>(context, listen: false).uid;
    _getMyContents(uid!);
    _getGroupUsers();
    _getGroupDetail();
    _friends = Provider.of<UserData>(context, listen: false).friends;
  }

  Future<void> _addCalendarToGroup(
      String? gid, String? uid, String? calendar_id) async {
    await SetGroupPrimaryCalendar()
        .setGroupPrimaryCalendar(gid, uid, calendar_id);
  }
  Future<void> _getMyContents(String uid) async {
    _MyCalendar = Provider.of<UserData>(context, listen: false).MyCalendar;
    _MyContents = Provider.of<UserData>(context, listen: false).MyContentsChoice;
    selectedContent = await _getCurrentUserContent(widget.groupId!, uid);
    String selectedCalId = await GetGroupPrimaryCalendar().getGroupPrimaryCalendar(widget.groupId,uid);
    selectedCalendar = _MyCalendar.firstWhere(
          (element) => element.calendar_id == selectedCalId,
      orElse: () => _MyCalendar[0],
    );
    setState(() {});
  }

  Future<MyContentsInformation?> _getCurrentUserContent(
      String gid, String uid) async {
    List<ContentsInformation>? contents =
      await GetContentInGroup().getContentInGroup(gid);
    if (contents?.isNotEmpty == true) {
      return _MyContents.firstWhere(
            (content) => contents!.any((groupContent) =>
        groupContent.uid == uid && content.cid == groupContent.cid),
        orElse: () => _MyContents[0],
      );
    }
    return _MyContents[0];
  }

  Future<void> _getGroupUsers() async {
    users = await GetUserInGroup().getUserInGroup(widget.groupId!);
    setState(() {});
  }

  Future<void> _addContentToGroup(String gid, String cid) async {
    await AddContentsToGroup().addContentsToGroup(gid, cid);
  }

  Future<void> _removeContentFromGroup(String gid, String cid) async {
    await RemoveContentsFromGroup().removeContentsFromGroup(gid, cid);
  }

  Future<void> _getGroupDetail() async {
    _groupDetail = await GetGroupDetail().getGroupDetail(widget.groupId);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.AppBarCol,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('設定',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("共有するコンテンツを選択", style: bigFont),
            if (_MyContents.isNotEmpty)
              DropdownButtonFormField<MyContentsInformation>(
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: GlobalColor.MainCol),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: GlobalColor.MainCol),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                value: selectedContent,
                items: _MyContents.map((MyContentsInformation content) {
                  return DropdownMenuItem<MyContentsInformation>(
                    value: content,
                    child: Text(content.cname),
                  );
                }).toList(),
                onChanged: (MyContentsInformation? newValue) async {
                  if (newValue != null) {
                    selectedContent?.cid != '';
                    if (selectedContent?.cid != '') {
                      await _removeContentFromGroup(
                          widget.groupId!, selectedContent!.cid);
                    }
                    setState(() {
                      selectedContent = newValue;
                    });
                    if (newValue.cname != 'なし') {
                      await _addContentToGroup(widget.groupId!, newValue.cid);
                    }
                  }
                },
              ),SizedBox(height: 20),
            Text("予定追加先カレンダーを選択", style: bigFont),
            if (_MyCalendar.isNotEmpty)
              DropdownButtonFormField<CalendarInformation>(
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: GlobalColor.MainCol),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: GlobalColor.MainCol),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                value: selectedCalendar,
                items: _MyCalendar.map((CalendarInformation content) {
                  return DropdownMenuItem<CalendarInformation>(
                    value: content,
                    child: Text(content.summary),
                  );
                }).toList(),
                onChanged: (CalendarInformation? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      selectedCalendar = newValue;
                    });
                    if (newValue.summary != 'ない') {
                      //await _addContentToGroup(widget.groupId!, newValue.summary);
                      await _addCalendarToGroup(widget.groupId, uid, selectedCalendar?.calendar_id);
                    }
                  }
                },
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
