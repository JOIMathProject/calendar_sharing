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
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getCalendars(uid!);
    //get selected calendars
    _getSelectedCalendars(uid!, widget.cid!);
  }

  Future<void> _getCalendars(String uid) async {
    calendars = await GetMyCalendars().getMyCalendars(uid);
    setState(() {}); // Trigger a rebuild once the content is loaded
  }

  Future<void> _getSelectedCalendars(String uid, String cid) async {
    selectedCalendars = await GetMyContentCalendars().getMyContentCalenders(uid, cid);
    print(selectedCalendars.length);
    setState(() {}); // Trigger a rebuild once the content is loaded
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
            ElevatedButton(
              onPressed: () {
                _showDeleteConfirmationDialog(context, widget.cid!, widget.contentsName!);
              },
              child: Text('マイコンテンツを削除'),
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
                    selectedCalendars.add(calendar);
                  }else{
                    selectedCalendars.remove(calendar);
                  }
                });
              },
            ),
      ],
    );
  }

  Future<void> _deleteContent(String uid, String cid) async {
    await DeleteMyContents().deleteMyContents(uid, cid);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _showDeleteConfirmationDialog(BuildContext context, String cid, String cname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('マイコンテンツを削除'),
          content: Text('本当にマイコンテンツ"$cname"を削除しますか? この操作は取り消せません。'),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('削除', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                String? uid = Provider.of<UserData>(context, listen: false).uid;
                await _deleteContent(uid!, cid);
              },
            ),
          ],
        );
      },
    );
  }
}