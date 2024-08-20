import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as global_colors;
import 'package:provider/provider.dart';
import 'package:calendar_sharing/services/UserData.dart';

class CreateMyContents extends StatefulWidget {
  @override
  _CreateMyContentsState createState() => _CreateMyContentsState();
}

class _CreateMyContentsState extends State<CreateMyContents> {
  String title = '';
  List<CalendarInformation> selectedCalendars = [];
  TextStyle bigFont = TextStyle(fontSize: 20);
  List<CalendarInformation> calendars = [];
  String cid = '';
  @override
  void initState() {
    super.initState();
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    _getCalendars(uid!);
  }

  Future<void> _getCalendars(String uid) async {
    calendars = await GetMyCalendars().getMyCalendars(uid);
    setState(() {}); // Trigger a rebuild once the content is loaded
  }

  Future<void> _createEmptyContents(String uid, String title) async {
    cid = await CreateEmptyContents().createEmptyContents(uid, title);
    print('$cid');
  }

  Future<void> _addCalendarToContents(String uid,String cid, String calendar_id) async {
    await AddCalendarToContents().addCalendarToContents(uid,cid, calendar_id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('マイコンテンツの作成')),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(hintText: 'コンテンツ名'),
              onChanged: (String value) {
                setState(() {
                  title = value;
                });
              },
              style: TextStyle(fontSize: 25),
            ),
            SizedBox(height: 20),
            Text("Select calendars", style: bigFont),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  if (calendars.isEmpty)
                    Text('No calendars available')
                  else
                    for (var calendar in calendars)
                      CheckboxListTile(
                        title: Text(calendar.summary),
                        subtitle: Text(calendar.discription),
                        value: selectedCalendars.contains(calendar),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedCalendars.add(calendar);
                            } else {
                              selectedCalendars.remove(calendar);
                            }
                          });
                        },
                      ),
                ],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (selectedCalendars.isNotEmpty) {
                  // Code to make content with selected calendars
                  _makeContent(selectedCalendars);
                } else {
                  // Show a message if no calendar is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select at least one calendar')),
                  );
                }
              },
              child: Text('作成'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(100, 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makeContent(List<CalendarInformation> selectedCalendars) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await _createEmptyContents(uid!, title);
    for (var calendar in selectedCalendars) {
      print('cid is :${cid} Selected Calendar: ${calendar.calendar_id}');
      await _addCalendarToContents(uid, cid, calendar.calendar_id);
    }
  }
}
