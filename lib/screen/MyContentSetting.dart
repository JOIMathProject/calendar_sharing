import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool isEditingTitle = false;
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
        backgroundColor: GlobalColor.AppBarCol,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('マイコンテンツの設定', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            buildProfileField(
              context,
              label: 'コンテンツ名',
              controller: titleController,
              isEditing: isEditingTitle,
              restrictInput: false,
              onEditToggle: () {
                setState(() {
                  isEditingTitle = !isEditingTitle;
                });
              },
              onSave: () {
                if(titleController.text.isNotEmpty && titleController.text != widget.contentsName){
                  _updateContents(Provider.of<UserData>(context, listen: false).uid! , widget.cid!, titleController.text);
                }
                setState(() {
                  isEditingTitle = false;
                });
              },
            ),
            SizedBox(height: 20),
            Text('カレンダーの編集', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              height: 300, // Adjust the height as needed
              child: _buildCalendarList(context),
            ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // Aligns children to the end (right)
          children: [
            ElevatedButton(
              onPressed: () {
                _updateMyContent(context, widget.cid!, title, selectedCalendars);
              },
              child: Text(
                '保存',
                style: TextStyle(fontSize: 15, color: GlobalColor.SubCol),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColor.MainCol,
              ),
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
    _updateCalendars(uid!, cid, selectedCalendars);
    Navigator.of(context).pop();
  }
  void _changeContentsName(BuildContext context, String cid, String title) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await UpdateMyContents().updateContents(uid!, cid, title);
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
Widget buildProfileField(
    BuildContext context, {
      required String label,
      required TextEditingController controller,
      required bool isEditing,
      required bool restrictInput, // New parameter to control input restriction
      required VoidCallback onEditToggle,
      required VoidCallback onSave,
    }) {
  // Add listener to enforce 15-character limit
  controller.addListener(() {
    final text = controller.text;
    if (text.length > 15) {
      // Trim the text to 15 characters and update the controller
      controller.text = text.substring(0, 15);
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  });

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        isEditing
            ? Expanded(
          child: TextField(
            maxLength: 15,
            controller: controller,
            style: TextStyle(fontSize: 18),
            decoration: InputDecoration(
              labelText: label,
              hintText: label,
            ),
            inputFormatters: restrictInput
                ? [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            ]
                : [], // No restriction if restrictInput is false
          ),
        )
            : Text(
            label == 'ユーザーID'
                ? '$label: @${controller.text}'
                : '$label: ${controller.text}',
            style: TextStyle(fontSize: 18)),
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit),
          onPressed: isEditing ? onSave : onEditToggle,
        ),
      ],
    ),
  );
}
