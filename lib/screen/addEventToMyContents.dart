import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;
import 'package:provider/provider.dart';
import '../services/APIcalls.dart';
import '../services/UserData.dart';
import 'package:intl/intl.dart';


// Renamed classes to follow Dart naming conventions
class AddEventToMyContents extends StatefulWidget {
  final String? cid;
  AddEventToMyContents({required this.cid});

  @override
  _AddEventToMyContentsState createState() => _AddEventToMyContentsState();
}

class _AddEventToMyContentsState extends State<AddEventToMyContents> {
  DateTime now = DateTime.now();
  DateTime _startDateTime = DateTime.now();
  // **Initialized _endDateTime to be one hour after _startDateTime**
  DateTime _endDateTime = DateTime.now().add(Duration(hours: 1));
  TextEditingController _summaryController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool isLocalAdd = true; // Default option is local add
  List<CalendarInformation> calendars = [];
  CalendarInformation? selectedCalendar;
  bool _isLoadingCalendars = true;

  @override
  void initState() {
    super.initState();
    _getSelectedCalendars(
        Provider.of<UserData>(context, listen: false).uid!, widget.cid!);

    _summaryController.addListener(() {
      setState(() {}); // Rebuild the widget when text changes
    });
    _descriptionController.addListener(() {
      setState(() {}); // Rebuild the widget when text changes
    });
  }

  Future<void> _getSelectedCalendars(String uid, String cid) async {
    final selectedCalendarsTmp =
        await GetMyContentCalendars().getMyContentCalenders(uid, cid);
    setState(() {
      calendars = selectedCalendarsTmp;
      _isLoadingCalendars = false;
    });
  }

  Future<void> addEvents(String cid, String summary, String description,
      DateTime startTime, DateTime endTime) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await AddEventToMyContentsLocal().addEventToMyContentsLocal(
        uid, cid, summary, description, startTime, endTime);
  }

  Future<void> addEventToGoogleCalendar(
      String summary,
      String description,
      DateTime startTime,
      DateTime endTime,
      CalendarInformation calendar) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await AddEventToTheCalendar().addEventToTheCalendar(
        uid, calendar.calendar_id, summary, description, startTime, endTime);
  }

  /// **Helper Function:** Adds minutes to a TimeOfDay, handling overflow.
  TimeOfDay addMinutesToTimeOfDay(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    final newHour = (totalMinutes ~/ 60) % 24;
    final newMinute = totalMinutes % 60;
    return TimeOfDay(hour: newHour, minute: newMinute);
  }

  Future<void> _pickStartDateTime() async {
    // Pick the Start Date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary:
                  GlobalColor.MainCol, // Header background color (selected day)
              onPrimary: Colors.black, // Header text color
              surface: GlobalColor.SubCol, // Dialog background color
              onSurface: Colors.black, // Body text color (dates)
            ),
            dialogBackgroundColor: GlobalColor.SubCol, // Dialog background
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: GlobalColor.MainCol,
                foregroundColor: GlobalColor.SubCol, // Button text color
                // backgroundColor can be set if needed
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Colors.black), // Date text color
              // You can customize other text styles if needed
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      // Pick the Start Time
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDateTime),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary:
                GlobalColor.timeDateSelectionCol, // Header background color (selected day)
                onPrimary: Colors.black, // Header text color
                surface: GlobalColor.SubCol, // Dialog background color
                onSurface: Colors.black, // Body text color (dates)
              ),
              dialogBackgroundColor: GlobalColor.SubCol, // Dialog background
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  backgroundColor: GlobalColor.timeDateSelectionCol,
                  foregroundColor: GlobalColor.SubCol, // Button text color
                  // backgroundColor can be set if needed
                ),
              ),
              textTheme: TextTheme(
                bodyMedium: TextStyle(color: Colors.black), // Date text color
                // You can customize other text styles if needed
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        DateTime newStartDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _startDateTime = newStartDateTime;

          // **Updated Logic:** If the new Start DateTime is after or equal to the current End DateTime,
          // adjust the End DateTime to be one hour after the new Start DateTime
          if (_endDateTime.isBefore(_startDateTime) ||
              _endDateTime.isAtSameMomentAs(_startDateTime)) {
            _endDateTime = _startDateTime.add(Duration(hours: 1));
          }
        });
      }
    }
  }

  Future<void> _pickEndDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _endDateTime.isBefore(_startDateTime) ? _startDateTime : _endDateTime,
      firstDate: _startDateTime, // End date cannot be before Start date
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary:
              GlobalColor.timeDateSelectionCol, // Header background color (selected day)
              onPrimary: Colors.black, // Header text color
              surface: GlobalColor.SubCol, // Dialog background color
              onSurface: Colors.black, // Body text color (dates)
            ),
            dialogBackgroundColor: GlobalColor.SubCol, // Dialog background
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: GlobalColor.timeDateSelectionCol,
                foregroundColor: GlobalColor.SubCol, // Button text color
                // backgroundColor can be set if needed
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Colors.black), // Date text color
              // You can customize other text styles if needed
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (_isSameDate(pickedDate, _startDateTime)) {
        // If the picked date is the same as the start date, use custom time picker
        // **Updated Logic:** Set minTime to startTime + 1 hour
        TimeOfDay minSelectableTime =
            addMinutesToTimeOfDay(TimeOfDay.fromDateTime(_startDateTime), 60);

        TimeOfDay? pickedTime = await _showCustomTimePicker(
          context,
          initialTime: TimeOfDay.fromDateTime(_endDateTime),
          minTime: minSelectableTime,
        );

        if (pickedTime != null) {
          DateTime selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          setState(() {
            _endDateTime = selectedDateTime;
          });
        }
      } else {
        // If the picked date is different from the start date, use standard time picker
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_endDateTime),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData(
                colorScheme: ColorScheme.light(
                  primary: GlobalColor
                      .MainCol, // Header background color (selected day)
                  onPrimary: Colors.black, // Header text color
                  surface: GlobalColor.SubCol, // Dialog background color
                  onSurface: Colors.black, // Body text color (dates)
                ),
                dialogBackgroundColor: GlobalColor.SubCol, // Dialog background
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    backgroundColor: GlobalColor.MainCol,
                    foregroundColor: GlobalColor.SubCol, // Button text color
                    // backgroundColor can be set if needed
                  ),
                ),
                textTheme: TextTheme(
                  bodyMedium: TextStyle(color: Colors.black), // Time text color
                  // You can customize other text styles if needed
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          DateTime selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          setState(() {
            _endDateTime = selectedDateTime;
          });
        }
      }
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Custom Time Picker that restricts selection to times >= minTime
  Future<TimeOfDay?> _showCustomTimePicker(BuildContext context,
      {required TimeOfDay initialTime, required TimeOfDay minTime}) async {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        // Generate a list of valid times starting from minTime in 15-minute increments
        List<TimeOfDay> validTimes = [];
        for (int hour = minTime.hour; hour <= 23; hour++) {
          int startMinute = (hour == minTime.hour) ? minTime.minute : 0;
          for (int minute = startMinute; minute < 60; minute += 15) {
            validTimes.add(TimeOfDay(hour: hour, minute: minute));
          }
        }

        return AlertDialog(
          title: Text('終了時間を設定してください'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: validTimes.length,
              itemBuilder: (BuildContext context, int index) {
                final time = validTimes[index];
                return ListTile(
                  title: Text(time.format(context)),
                  onTap: () {
                    Navigator.of(context).pop(time);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  void _addEvent() async {
    String summary = _summaryController.text;
    String description = _descriptionController.text;

    if (summary.isEmpty) {
      // Show SnackBar if summary is empty
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: GlobalColor.SnackCol,
          content: Text('予定名を入力してください',
              style: TextStyle(color: GlobalColor.SubCol))));
      return;
    }

    // **Validation:** Ensure endTime is at least 1 minute after startTime
    if (_endDateTime.difference(_startDateTime) < Duration(minutes: 1)) {
      // This condition should rarely be true due to UI restrictions,
      // but it's kept here for safety.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: GlobalColor.SnackCol,
          content: Text('終了時間は開始時間より1分後でなければなりません',
              style: TextStyle(color: GlobalColor.SubCol))));
      return;
    }

    try {
      if (isLocalAdd) {
        // Add event locally
        await addEvents(
            widget.cid!, summary, description, _startDateTime, _endDateTime);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: GlobalColor.SnackCol,
            content: Text('イベントがローカルに追加されました',
                style: TextStyle(color: GlobalColor.SubCol))));
      } else {
        // Add event to Google Calendar
        if (selectedCalendar == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: GlobalColor.SnackCol,
              content: Text('カレンダーを選択してください',
                  style: TextStyle(color: GlobalColor.SubCol))));
          return;
        }
        await addEventToGoogleCalendar(summary, description, _startDateTime,
            _endDateTime, selectedCalendar!);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: GlobalColor.SnackCol,
            content: Text('Googleカレンダーに予定が追加されました',
                style: TextStyle(color: GlobalColor.SubCol))));
      }
      Navigator.pop(context, true); // Navigate back after adding
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: GlobalColor.SnackCol,
          content: Text('イベントの追加に失敗しました',
              style: TextStyle(color: GlobalColor.SubCol))));
    }
    // Optionally, navigate back or clear fields after adding the event
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedFontSize = screenWidth * 0.036; // 4% of screen width

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.AppBarCol,
      ),
      body: Column(
        children: [
          Text('イベントを追加', style: TextStyle(fontSize: 30)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20.0),
              children: [
                TextField(
                  controller: _summaryController,
                  decoration: InputDecoration(
                    labelText: '予定名',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded border
                      borderSide: BorderSide.none, // Remove the default border
                    ),
                    filled: true,
                    fillColor: Colors.transparent, // Transparent since Container has color
                    contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    suffixIcon: _summaryController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _summaryController.clear();
                      },
                    )
                        : null,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: GlobalColor.MainCol,
                          width: 1.0), // Color and thickness of the bottom line
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: GlobalColor.MainCol,
                          width: 2.0), // Color and thickness when focused
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '概要',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded border
                      borderSide: BorderSide.none, // Remove the default border
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    suffixIcon: _descriptionController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _descriptionController.clear();
                      },
                    )
                        : null,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: GlobalColor.MainCol,
                          width: 1.0),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: GlobalColor.MainCol,
                          width: 2.0),
                    ),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('開始時刻'),
                          SizedBox(height: 5),
                          GestureDetector(
                            onTap: _pickStartDateTime,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${DateFormat('yyyy/MM/dd hh:mm').format(_startDateTime.toLocal())}'.split('.')[0],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('終了時刻'),
                          SizedBox(height: 5),
                          GestureDetector(
                            onTap: _pickEndDateTime,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${DateFormat('yyyy/MM/dd hh:mm').format(_endDateTime.toLocal())}'.split('.')[0],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text('追加先', style: TextStyle(fontSize: 20)),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isLocalAdd = true;
                          });
                        },
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: isLocalAdd,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  isLocalAdd = newValue!;
                                });
                              },
                            ),
                            Flexible(
                              child: Text(
                                'ローカル',
                                style: TextStyle(fontSize: calculatedFontSize),
                                overflow: TextOverflow.ellipsis, // テキストが長すぎる場合に省略記号を表示
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isLocalAdd = false;
                          });
                        },
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: isLocalAdd,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  isLocalAdd = newValue!;
                                });
                              },
                            ),
                            Flexible(
                              child: Text(
                                'Googleカレンダー',
                                style: TextStyle(fontSize: calculatedFontSize),
                                overflow: TextOverflow.ellipsis, // テキストが長すぎる場合に省略記号を表示
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (!isLocalAdd)
                  _isLoadingCalendars
                      ? Center(child: CircularProgressIndicator())
                      : calendars.isEmpty
                      ? Text('利用可能なカレンダーがありません')
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('カレンダーを選択', style: TextStyle(fontSize: 20)),
                      DropdownButton<CalendarInformation>(
                        value: selectedCalendar,
                        hint: Text('カレンダーを選択'),
                        onChanged: (CalendarInformation? newValue) {
                          setState(() {
                            selectedCalendar = newValue!;
                          });
                        },
                        items: calendars
                            .map<DropdownMenuItem<CalendarInformation>>(
                                (CalendarInformation value) {
                              return DropdownMenuItem<CalendarInformation>(
                                value: value,
                                child: Text(value.summary),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: _addEvent,
          child: Text('追加',
              style: TextStyle(color: GlobalColor.SubCol, fontSize: 30)),
          style: ElevatedButton.styleFrom(
            backgroundColor: GlobalColor.MainCol,
            padding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );

  }
}
