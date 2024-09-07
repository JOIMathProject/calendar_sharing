import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;

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
    events = await GetMyContentsSchedule()
        .getMyContentsSchedule(uid, widget.cid, '2024-01-00', '2025-12-11');
    setState(() {});
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
        actions: [
          DropdownButton<CalendarView>(
            value: _currentView,
            icon: Icon(Icons.arrow_drop_down),
            onChanged: (CalendarView? newView) {
              setState(() {
                if (newView != null) _currentView = newView;
              });
            },
            items: [
              DropdownMenuItem(
                value: CalendarView.month,
                child: Text('Month View'),
              ),
              DropdownMenuItem(
                value: CalendarView.week,
                child: Text('Week View'),
              ),
              DropdownMenuItem(
                value: CalendarView.day,
                child: Text('Day View'),
              ),
            ],
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
              color: GlobalColor.MainCol,
            ),
            child: Center(
              child: Text(
                appointment.subject,
                style: TextStyle(
                  fontSize: 11,
                  color: GlobalColor.SubCol,
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
                  content: Text(appointment.notes ?? '概要なし'),
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
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
