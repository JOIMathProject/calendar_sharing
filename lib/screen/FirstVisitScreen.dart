import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/APIcalls.dart';
import '../services/UserData.dart';
import '../setting/color.dart' as GlobalColor;

class FirstVisitScreen extends StatefulWidget {
  final String groupId;
  final bool isFriend;

  const FirstVisitScreen({
    Key? key,
    required this.groupId,
    required this.isFriend,
  }) : super(key: key);

  @override
  _FirstVisitScreenState createState() => _FirstVisitScreenState();
}

class _FirstVisitScreenState extends State<FirstVisitScreen> {
  MyContentsInformation? selectedContent;
  CalendarInformation? selectedCalendar;
  List<MyContentsInformation> _MyContents = [];
  List<CalendarInformation> _MyCalendar = [];
  MyContentsInformation? usedContent;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Fetch data from providers or APIs
    _MyContents =
        Provider.of<UserData>(context, listen: false).MyContentsChoice;
    _MyCalendar = Provider.of<UserData>(context, listen: false).MyCalendar;

    // Fetch the current user's content
    usedContent = await _getCurrentUserContent(
      widget.groupId,
      Provider.of<UserData>(context, listen: false).uid!,
    );

    // Set the selected content and calendar
    setState(() {
      selectedContent = _MyContents.contains(usedContent)
          ? usedContent
          : (_MyContents.isNotEmpty ? _MyContents[0] : null);
      selectedCalendar = _MyCalendar.isNotEmpty ? _MyCalendar[0] : null;
    });
  }

  Future<MyContentsInformation?> _getCurrentUserContent(
      String gid, String uid) async {
    List<ContentsInformation>? contents =
        await GetContentInGroup().getContentInGroup(gid);
    if (contents?.isNotEmpty == true) {
      return _MyContents.firstWhere(
        (content) => contents!.any((groupContent) =>
            groupContent.uid == uid && content.cid == groupContent.cid),
        orElse: () => _MyContents[0]!,
      );
    }
    return _MyContents.isNotEmpty ? _MyContents[0] : null;
  }

  @override
  Widget build(BuildContext context) {
    // It's better to initialize _MyContents and _MyCalendar in _initializeData
    // and avoid reassigning them in the build method to prevent inconsistencies
    // _MyCalendar = Provider.of<UserData>(context, listen: false).MyCalendar;
    // _MyContents = Provider.of<UserData>(context, listen: false).MyContentsChoice;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: GlobalColor.AppBarCol,
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'カレンダーとコンテンツを選択',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 32),
                  _buildContentSelection(),
                  SizedBox(height: 32),
                  _buildCalendarSelection(),
                  SizedBox(height: 48),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "共有するコンテンツを選択",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        if (_MyContents.isNotEmpty)
          DropdownButtonFormField<MyContentsInformation>(
            value: selectedContent,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: GlobalColor.MainCol),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: GlobalColor.MainCol),
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: _MyContents.map((MyContentsInformation content) {
              return DropdownMenuItem<MyContentsInformation>(
                value: content,
                child: Text(content.cname),
              );
            }).toList(),
            onChanged: (MyContentsInformation? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedContent = newValue;
                });
              }
            },
          ),
      ],
    );
  }

  Widget _buildCalendarSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "予定追加先カレンダーを選択",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        if (_MyCalendar.isNotEmpty)
          DropdownButtonFormField<CalendarInformation>(
            value: selectedCalendar,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: GlobalColor.MainCol),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: GlobalColor.MainCol),
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: _MyCalendar.map((CalendarInformation calendar) {
              return DropdownMenuItem<CalendarInformation>(
                value: calendar,
                child: Text(calendar.summary),
              );
            }).toList(),
            onChanged: (CalendarInformation? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedCalendar = newValue;
                });
              }
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('登録',
                  style: TextStyle(fontSize: 18, color: GlobalColor.SubCol)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColor.MainCol,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _handleRegistration,
          ),
        ),
        if (!widget.isFriend) ...[
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('グループから離脱', style: TextStyle(fontSize: 18,color: GlobalColor.logOutCol)),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _handleLeaveGroup,
            ),
          ),
        ],
      ],
    );
  }

  void _handleRegistration() async {
    if (selectedContent?.cname != 'なし') {
      await _addContentToGroup(widget.groupId, selectedContent!.cid);
    }
    await _addCalendarToGroup(
      widget.groupId,
      Provider.of<UserData>(context, listen: false).uid,
      selectedCalendar!.calendar_id,
    );
    await SetOpened().setOpened(
      Provider.of<UserData>(context, listen: false).uid,
      widget.groupId,
    );
    Navigator.of(context).pop();
  }

  void _handleLeaveGroup() {
    _removeUserFromGroup(
      widget.groupId,
      Provider.of<UserData>(context, listen: false).uid!,
    );
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }
}

Future<void> _removeUserFromGroup(String gid, String Removeuid) async {
  await DeleteUserFromGroup().deleteUserFromGroup(gid, Removeuid);
}

Future<void> _addContentToGroup(String gid, String cid) async {
  await AddContentsToGroup().addContentsToGroup(gid, cid);
}

Future<void> _addCalendarToGroup(
    String gid, String? uid, String calendar_id) async {
  await SetGroupPrimaryCalendar()
      .setGroupPrimaryCalendar(gid, uid, calendar_id);
}
