import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;

class MyContentSetting extends StatefulWidget {
  final String? cid;
  final String? contentsName;
  MyContentSetting({required this.cid, required this.contentsName});

  @override
  _MyContentSettingState createState() => _MyContentSettingState();
}

class _MyContentSettingState extends State<MyContentSetting> {
  String title = '';
  List<CalendarInformation> calendars = [];
  List<CalendarInformation> selectedCalendars = [];
  final List<CalendarInformation> selectedCalendarsFirst = [];
  final TextEditingController titleController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    titleController.text = widget.contentsName!;
    title = widget.contentsName!;
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _reloadContents();
  }

  void _reloadContents() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    if (uid != null) {
      await _getCalendars(uid);
      await _getSelectedCalendars(uid, widget.cid!);
      setState((){});
    }
  }

  Future<void> _getCalendars(String uid) async {
    calendars = await GetMyCalendars().getMyCalendars(uid);
  }

  Future<void> _getSelectedCalendars(String uid, String cid) async {
    final selectedCalendarsTmp = await GetMyContentCalendars().getMyContentCalenders(uid, cid);
    selectedCalendars = [];
    for (var calendar in calendars){
      for (var selectedCalendar in selectedCalendarsTmp){
        if (calendar.calendar_id == selectedCalendar.calendar_id){
          selectedCalendars.add(calendar);
          selectedCalendarsFirst.add(calendar);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('マイコンテンツの設定', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(hintText: 'コンテンツ名'),
              onChanged: (String value) {
                setState(() {
                  title = value;
                });
              },
              controller: titleController,
              style: TextStyle(fontSize: 25),
            ),
            SizedBox(height: 20),
            Text('カレンダーの編集', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(child: _buildCalendarList(context)),
            Row(
              children: [
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _updateMyContent(context, widget.cid!, title, selectedCalendars);
                  },
                  child: Text('保存',style:TextStyle(color: GlobalColor.SubCol)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarList(BuildContext context) {
    return ListView(
      children: [
        if (calendars.isEmpty)
          Text('カレンダーなし')
        else
          for (var calendar in calendars)
            CheckboxListTile(
              title: Text(calendar.summary),
              subtitle: Text(calendar.discription),
              value: selectedCalendars.contains(calendar),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true){
                    if (!selectedCalendars.contains(calendar)){
                      selectedCalendars.add(calendar);
                    }
                  }else{
                    //存在するかどうか
                    if(selectedCalendars.contains(calendar)){
                      selectedCalendars.remove(calendar);
                    }
                  }
                });
              },
              checkColor: GlobalColor.SubCol,
              fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return GlobalColor.MainCol;
                }
                return null;
              }),
            ),
      ],
    );
  }

  Future<void> _deleteContent(String uid, String cid) async {
    await DeleteMyContents().deleteMyContents(uid, cid);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
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
              },
            ),
          ],
        );
      },
    );
  }
  void _updateMyContent(BuildContext context, String cid, String title, List<CalendarInformation> selectedCalendars) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    if (title.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }
    if (selectedCalendars.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('最低でも一つはカレンダーを選択してください')),
      );
      return;
    }
    if (title != widget.contentsName){
      _updateContents(uid!, cid, title);
    }
    _updateCalendars(uid!, cid, selectedCalendars);
    Navigator.of(context).pop();
  }
  void _updateCalendars(String uid, String cid, List<CalendarInformation> selectedCalendars) async {
    List<CalendarInformation> addCalendars = [];
    List<CalendarInformation> deleteCalendars = [];
    for (var calendar in selectedCalendars){
      if (!selectedCalendarsFirst.contains(calendar)){
        addCalendars.add(calendar);
      }
    }
    for (var calendar in selectedCalendarsFirst){
      if (!selectedCalendars.contains(calendar)){
        deleteCalendars.add(calendar);
      }
    }
    for (var calendar in addCalendars){
      await AddCalendarToContents().addCalendarToContents(uid!, cid, calendar.calendar_id);
    }
    for (var calendar in deleteCalendars){
      await DeleteCalendarFromContents().deleteCalendarFromContents(uid!, cid, calendar.calendar_id);
    }
  }
  void _updateContents(String uid, String cid, String title) async {
    await UpdateMyContents().updateContents(uid, cid, title);
  }
}