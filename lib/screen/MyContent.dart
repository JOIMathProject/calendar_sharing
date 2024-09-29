import 'dart:async';

import 'package:calendar_sharing/screen/addEventToMyContents.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
                      child: Column(
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
                                  child: Text('Googleカレンダーにアップロード'),
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
