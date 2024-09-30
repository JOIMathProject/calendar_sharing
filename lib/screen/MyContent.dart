import 'dart:async';

import 'package:calendar_sharing/screen/addEventToMyContents.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;

import 'MyContentSetting.dart';

/// Helper class to parse the `notes` field in Appointment
class ParsedNotes {
  final String description;
  final String eventId;
  final bool isLocal;
  final String calendarId;

  ParsedNotes({
    required this.description,
    required this.eventId,
    required this.isLocal,
    required this.calendarId,
  });

  factory ParsedNotes.fromString(String notes) {
    List<String> parts = notes.split('|');
    if (parts.length >= 4) {
      return ParsedNotes(
        description: parts[0],
        eventId: parts[1],
        isLocal: parts[2] == '1',
        calendarId: parts[3],
      );
    } else {
      // Fallback in case the notes don't have the expected format
      return ParsedNotes(
        description: notes,
        eventId: '',
        isLocal: false,
        calendarId: '',
      );
    }
  }
}

class MyContent extends StatefulWidget {
  final String? cid;
  final String? contentsName;
  MyContent({required this.cid, required this.contentsName});

  @override
  _MyContentState createState() => _MyContentState();
}

class _MyContentState extends State<MyContent> {
  var httpClientO = null;
  var googleCalendarApiO = null;
  List<Appointment> events = [];
  CalendarView _currentView = CalendarView.week;
  List<CalendarInformation> calendars = [];
  CalendarInformation? selectedCalendar;
  bool _isLoadingCalendars = true;

  DateTime currentDate = DateTime.now();

  DateTime startDate = DateTime(2024, 01, 01);

  DateTime endDate = DateTime(2025, 01, 01);
  String formattedStartDate = '2024-01-01';
  String formattedEndDate = '2025-01-01';

  @override
  void initState() {
    super.initState();

    startDate = DateTime(currentDate.year, currentDate.month - 3, currentDate.day);
    endDate = DateTime(currentDate.year, currentDate.month + 6, currentDate.day);

    formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
    _getCalendar();
    _getSelectedCalendars(
        Provider.of<UserData>(context, listen: false).uid!, widget.cid!);
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
      }
      _getCalendar();
      setState(() {});
    });
  }

  Future<void> _getSelectedCalendars(String uid, String cid) async {
    final selectedCalendarsTmp =
        await GetMyContentCalendars().getMyContentCalenders(uid, cid);
    setState(() {
      calendars = selectedCalendarsTmp;
      _isLoadingCalendars = false;
      selectedCalendar = selectedCalendarsTmp[0];
    });
  }

  Future<void> _getCalendar() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;

    // Fetch events from your API
    List<eventInformation> eventsCollection = await GetMyContentsSchedule()
        .getMyContentsSchedule(uid, widget.cid, formattedStartDate, formattedEndDate);

    List<Appointment> fetchedAppointments = eventsCollection.map((event) {
      // Concatenate description with metadata separated by '|'
      String notes =
          "${event.description}|${event.event_id}|${event.is_local ? '1' : '0'}|${event.calendar_id ?? ''}";

      return Appointment(
        startTime: event.startTime,
        endTime: event.endTime,
        subject: event.summary,
        notes: notes, // Store description and metadata in notes
        color: event.is_local
            ? Colors.blue
            : GlobalColor.MainCol, // Different colors
      );
    }).toList();

    setState(() {
      events = fetchedAppointments;
    });
  }

  Future<void> _deleteEvent(String calendar_id, String event_id) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await DeleteEventFromCalendar()
        .deleteEventFromCalendar(uid, calendar_id, event_id);
    await _getCalendar();
    setState(() {});
    Navigator.pop(context);
    // Refresh the calendar after deletion
  }

  Future<void> _deleteLocalEvents(String event_id) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await DeleteLocalEventFromMyContents()
        .deleteLocalEventFromMyContents(uid, widget.cid, event_id);
    Navigator.pop(context);
    // Refresh the calendar after deletion
    await _getCalendar();
  }

  Future<void> _uploadLocalEvents(String calendar_id, String event_id) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await AddLocalToGoogleCal()
        .addLocalToGoogleCal(uid, widget.cid, event_id, calendar_id);
    Navigator.pop(context);
    // Optionally, refresh the calendar or show a confirmation message
    await _getCalendar();
  }

  Future<void> updateGoogleEvent(String calendar_id, String event_id, String summary, String description, DateTime startTime,DateTime endTime) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await GoogleEventEdit()
        .googleEventEdit(uid, calendar_id,event_id,summary,description,startTime,endTime);
    Navigator.pop(context);
    // Optionally, refresh the calendar or show a confirmation message
    await _getCalendar();
  }
  Future<void> updateLocalEvent(String event_id, String summary, String description, DateTime startTime,DateTime endTime) async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    await LocalEventEdit()
        .localEventEdit(uid, widget.cid,event_id,summary,description,startTime,endTime);
    Navigator.pop(context);
    // Optionally, refresh the calendar or show a confirmation message
    await _getCalendar();
  }
  String Description = '';
  String title = '';
  TextEditingController summaryController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    GoogleSignIn? gUser = Provider.of<UserData>(context).googleUser;
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.contentsName ?? ''),
          backgroundColor: GlobalColor.AppBarCol,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyContentSetting(
                      cid: widget.cid,
                      contentsName: widget.contentsName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SfCalendar(
          key: ValueKey(_currentView),
          view: _currentView,
          timeZone: 'Japan',
          headerHeight: 50,
          dataSource: MeetingDataSource(events),
          showWeekNumber: true,
          showDatePickerButton: true,
          headerDateFormat: 'yyyy MMMM',
          selectionDecoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
          ),
          todayHighlightColor: GlobalColor.MainCol,
          todayTextStyle: TextStyle(
            color: GlobalColor.SubCol,
            fontWeight: FontWeight.bold,
          ),
          showTodayButton: true,
          cellBorderColor: GlobalColor.Calendar_grid_color,
          timeSlotViewSettings: TimeSlotViewSettings(
            timeFormat: 'H:mm',
          ),
          appointmentBuilder:
              (BuildContext context, CalendarAppointmentDetails details) {
            final Appointment appointment = details.appointments.first;
            return Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: appointment.color, // Use the color from the Appointment
              ),
              child: Center(
                child: Text(
                  appointment.subject,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white, // Adjust based on background color
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),
            );
          },
          onTap: (CalendarTapDetails details) {if (details.targetElement == CalendarElement.appointment) {
            final Appointment appointment = details.appointments!.first;
            ParsedNotes parsedNotes = ParsedNotes.fromString(appointment.notes ?? '');

            // Initialize the TextEditingController once before the modal opens
            TextEditingController summaryController = TextEditingController(text: appointment.subject);
            TextEditingController descriptionController = TextEditingController(text: parsedNotes.description);

            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // Allow the bottom modal to expand as needed
              backgroundColor: GlobalColor.SubCol, // Adjust the background color if needed
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // Rounded top corners
              ),
              builder: (BuildContext context) {
                // Local variable to manage the selected calendar within the bottom modal
                CalendarInformation? localSelectedCalendar = selectedCalendar;

                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // Minimize vertical space usage
                            children: [
                              // Title
                              Text(
                                appointment.subject,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 20),

                              // Description Text
                              Text(
                                parsedNotes.description.isNotEmpty
                                    ? parsedNotes.description
                                    : '概要なし', // 'No summary' in Japanese
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 20), // Spacing between description and dropdown

                              // DropdownButton with Orange Tint
                              if (parsedNotes.isLocal)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: GlobalColor.MainColSub, // Optional: Orange border
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButton<CalendarInformation>(
                                    isExpanded: true, // Makes dropdown take full width
                                    value: localSelectedCalendar,
                                    hint: Text('カレンダーを選択'),
                                    onChanged: (CalendarInformation? newValue) {
                                      setState(() {
                                        localSelectedCalendar = newValue!;
                                      });
                                    },
                                    items: calendars.map<DropdownMenuItem<CalendarInformation>>(
                                          (CalendarInformation value) {
                                        return DropdownMenuItem<CalendarInformation>(
                                          value: value,
                                          child: Text(value.summary),
                                        );
                                      },
                                    ).toList(),
                                    underline: SizedBox(), // Removes the default underline
                                  ),
                                ),

                              if (parsedNotes.isLocal)
                                SizedBox(height: 10), // Space after dropdown

                              // Row to hold '削除' and 'Googleカレンダーにアップロード' buttons at the bottom
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensure space between the two buttons
                                children: [
                                  TextButton(
                                    child: Text(
                                      '削除',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      if (parsedNotes.isLocal) {
                                        _deleteLocalEvents(parsedNotes.eventId);
                                      } else {
                                        _deleteEvent(parsedNotes.calendarId, parsedNotes.eventId);
                                      }
                                    },
                                  ),

                                  // 'Googleカレンダーにアップロード' Button
                                  if (parsedNotes.isLocal)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: GlobalColor.ItemCol, // Background color (change as needed)
                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Reduced padding for smaller size
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8), // Rounded corners
                                        ),
                                        textStyle: TextStyle(fontSize: 14), // Optional: Reduce font size
                                      ),
                                      child: Text('Googleカレンダーに追加'),
                                      onPressed: () {
                                        if (localSelectedCalendar != null) {
                                          _uploadLocalEvents(
                                            localSelectedCalendar!.calendar_id,
                                            parsedNotes.eventId,
                                          );
                                        } else {
                                          // Show a warning if no calendar is selected
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('カレンダーを選択してください。')),
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: GlobalColor.SubCol, // Background color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (BuildContext context) {
                                    // Initialize values with current event data
                                    DateTime startTime = appointment.startTime;
                                    DateTime endTime = appointment.endTime;

                                    Duration eventDuration = endTime.difference(startTime);

                                    int selectedHours = eventDuration.inHours;
                                    int selectedMinutes = eventDuration.inMinutes.remainder(60);

                                    return StatefulBuilder(
                                      builder: (BuildContext context, StateSetter setState) {
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 16, right: 16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Title for editing event
                                              Text(
                                                'イベントを編集',
                                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 20),

                                              TextField(
                                                controller: summaryController,
                                                maxLength: 15,
                                                decoration: InputDecoration(
                                                  labelText: '予定名',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10), // Keep the rounded corners
                                                    borderSide: BorderSide.none, // No border for the outer edge
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.transparent, // Transparent as the Container has color
                                                  contentPadding: EdgeInsets.symmetric(
                                                    vertical: 5, horizontal: 10,
                                                  ),
                                                  enabledBorder: UnderlineInputBorder(
                                                    borderSide: BorderSide(color: GlobalColor.MainCol, width: 1.0), // Color and thickness of the bottom line
                                                  ),
                                                  focusedBorder: UnderlineInputBorder(
                                                    borderSide: BorderSide(color: GlobalColor.MainCol, width: 2.0), // Color and thickness when focused
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              TextField(
                                                controller: descriptionController,
                                                maxLength: 50,
                                                decoration: InputDecoration(
                                                  labelText: '概要',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10), // Keep the rounded corners
                                                    borderSide: BorderSide.none, // No border for the outer edge
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.transparent, // Transparent as the Container has color
                                                  contentPadding: EdgeInsets.symmetric(
                                                    vertical: 5, horizontal: 10,
                                                  ),
                                                  enabledBorder: UnderlineInputBorder(
                                                    borderSide: BorderSide(color: GlobalColor.MainCol, width: 1.0), // Color and thickness of the bottom line
                                                  ),
                                                  focusedBorder: UnderlineInputBorder(
                                                    borderSide: BorderSide(color: GlobalColor.MainCol, width: 2.0), // Color and thickness when focused
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 10),

                                              // Start Time Picker
                                              Row(
                                                children: [
                                                  Text('開始時間: '),
                                                  Spacer(),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final picked = await showTimePicker(
                                                        context: context,
                                                        initialTime: TimeOfDay.fromDateTime(startTime),
                                                      );
                                                      if (picked != null) {
                                                        setState(() {
                                                          startTime = DateTime(
                                                            startTime.year,
                                                            startTime.month,
                                                            startTime.day,
                                                            picked.hour,
                                                            picked.minute,
                                                          );
                                                          endTime = startTime.add(eventDuration); // Update endTime
                                                        });
                                                      }
                                                    },
                                                    child:
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                          vertical: 12, horizontal: 20),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(color: Colors.grey),
                                                        borderRadius: BorderRadius.circular(5),
                                                      ),
                                                      child: Text("${TimeOfDay.fromDateTime(startTime).format(context)}",
                                                        style: TextStyle(
                                                            color: Colors.black87, fontSize: 16),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 10),

                                              // Event Duration Picker (Hours and Minutes)
                                              Row(
                                                children: [
                                                  Text('イベント長さ: '),
                                                  Spacer(),
                                                  GestureDetector(
                                                    onTap: () {
                                                      showModalBottomSheet(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return Container(
                                                            height: 250,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Expanded(
                                                                  child: CupertinoPicker(
                                                                    itemExtent: 32.0,
                                                                    onSelectedItemChanged: (int index) {
                                                                      setState(() {
                                                                        selectedHours = index;
                                                                        eventDuration = Duration(hours: selectedHours, minutes: selectedMinutes);
                                                                        endTime = startTime.add(eventDuration); // Update endTime
                                                                      });
                                                                    },
                                                                    children: List<Widget>.generate(24, (int index) {
                                                                      return Center(
                                                                        child: Text("$index 時間"),
                                                                      );
                                                                    }),
                                                                    scrollController: FixedExtentScrollController(
                                                                      initialItem: selectedHours,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: CupertinoPicker(
                                                                    itemExtent: 32.0,
                                                                    onSelectedItemChanged: (int index) {
                                                                      setState(() {
                                                                        selectedMinutes = index;
                                                                        eventDuration = Duration(hours: selectedHours, minutes: selectedMinutes);
                                                                        endTime = startTime.add(eventDuration); // Update endTime
                                                                      });
                                                                    },
                                                                    children: List<Widget>.generate(60, (int index) {
                                                                      return Center(
                                                                        child: Text("$index 分"),
                                                                      );
                                                                    }),
                                                                    scrollController: FixedExtentScrollController(
                                                                      initialItem: selectedMinutes,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    child:
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                          vertical: 12, horizontal: 10),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(color: Colors.grey),
                                                        borderRadius: BorderRadius.circular(5),
                                                      ),
                                                      child: Text("$selectedHours 時間 $selectedMinutes 分",
                                                        style: TextStyle(
                                                            color: Colors.black87, fontSize: 16),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 20),

                                              // Submit Button
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Add your desired padding
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: GlobalColor.MainCol,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        '保存',
                                                        style: TextStyle(color: GlobalColor.SubCol),
                                                      ),
                                                      onPressed: () {
                                                        // Call update function based on the type of event
                                                        if(summaryController.text == ''){
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                title: Text('エラー'),
                                                                content: Text('イベント名を指定してください'),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.of(context).pop(); // Close the dialog
                                                                    },
                                                                    child: Text('了解'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        }
                                                        else if(eventDuration == Duration.zero){
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                title: Text('エラー'),
                                                                content: Text('イベントの長さを指定してください'),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.of(context).pop(); // Close the dialog
                                                                    },
                                                                    child: Text('了解'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        }
                                                        else if (parsedNotes.isLocal) {
                                                          updateLocalEvent(
                                                            parsedNotes.eventId,
                                                            summaryController.text,
                                                            descriptionController.text,
                                                            startTime,
                                                            endTime,
                                                          );
                                                        } else {
                                                          updateGoogleEvent(
                                                            parsedNotes.calendarId,
                                                            parsedNotes.eventId,
                                                            summaryController.text,
                                                            descriptionController.text,
                                                            startTime,
                                                            endTime,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );

                                print('Edit icon tapped');
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );

          }

          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            bool? eventAdded = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEventToMyContents(
                  cid: widget.cid,
                ),
              ),
            );

            if (eventAdded != null && eventAdded) {
              // Refresh the calendar by fetching events again
              await _getCalendar();
            }
          },
          child: Icon(Icons.add, color: GlobalColor.SubCol),
          backgroundColor: GlobalColor.MainCol,
        ));
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
