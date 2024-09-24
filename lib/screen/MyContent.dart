import 'package:calendar_sharing/screen/addEventToMyContents.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;

import 'MyContentSetting.dart';

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

  @override
  void initState() {
    super.initState();
    _getCalendar();
  }

  Future<void> _getCalendar() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;

    // Corrected date format
    List<eventInformation> eventsCollection = await GetMyContentsSchedule()
        .getMyContentsSchedule(uid, widget.cid, '2024-01-01', '2025-12-11');

    List<Appointment> fetchedAppointments = eventsCollection.map((event) {
      return Appointment(
        startTime: event.startTime,
        endTime: event.endTime,
        subject: event.summary,
        notes: event.description, // Map description to notes
        color: event.is_local ? GlobalColor.MainCol : Colors.red, // Different colors
      );
    }).toList();

    setState(() {
      events = fetchedAppointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    GoogleSignIn? gUser = Provider.of<UserData>(context).googleUser;
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.contentsName ?? ''),
          backgroundColor: GlobalColor.SubCol,
          flexibleSpace: Container(
            color: GlobalColor.SubCol,
          ),
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
          onTap: (CalendarTapDetails details) {
            if (details.targetElement == CalendarElement.appointment) {
              final Appointment appointment = details.appointments!.first;
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(appointment.subject),
                    content: Text(appointment.notes?.length == 0 ? '概要なし': appointment.notes!),
                    actions: <Widget>[
                      TextButton(
                        child: Text('閉じる'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
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
        )
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
