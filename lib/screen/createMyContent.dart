import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as global_colors;
import 'package:provider/provider.dart';
import 'package:calendar_sharing/services/UserData.dart';
import '../setting/color.dart' as GlobalColor;

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

  Future<void> _addCalendarToContents(String uid, String cid, String calendar_id) async {
    await AddCalendarToContents().addCalendarToContents(uid, cid, calendar_id);
  }
  TextEditingController contentsNameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.AppBarCol,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('マイコンテンツの作成', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 40),
            TextField(
              controller: contentsNameController,
              maxLength: 15,
              decoration: InputDecoration(
                labelText: 'コンテンツ名',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Keep the rounded corners
                  borderSide: BorderSide.none, // No border for the outer edge
                ),
                filled: true,
                fillColor: Colors.transparent, // Transparent as the Container has color
                contentPadding: EdgeInsets.symmetric(
                  vertical: 5, horizontal: 10,
                ),
                suffixIcon: title.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    contentsNameController.clear();
                    setState(() {
                      title = ''; // Clear the title value
                    });
                  },
                )
                    : null,
                // Add an underline only at the bottom
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: GlobalColor.MainCol, width: 1.0), // Color and thickness of the bottom line
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: GlobalColor.MainCol, width: 2.0), // Color and thickness when focused
                ),
              ),
              onChanged: (value) {
                setState(() {
                  title = value;
                });
              },
            ),
            SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft, // Align the text to the left
              child: Text("カレンダーを選択", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
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
                            if (value == true) {
                              selectedCalendars.add(calendar);
                            } else {
                              selectedCalendars.remove(calendar);
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
              ),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (selectedCalendars.isNotEmpty && title.isNotEmpty) {
                    // Code to make content with selected calendars
                    _makeContent(selectedCalendars);
                    Navigator.pop(context);
                  } else if(title.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('エラー'),
                          content: Text('コンテンツ名を指定してください'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }else{
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('エラー'),
                          content: Text('カレンダーを１つ以上指定してください'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text('作成', style: TextStyle(fontSize: 20, color: GlobalColor.SubCol)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColor.MainCol,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
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
