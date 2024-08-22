import 'dart:convert';

import 'package:calendar_sharing/screen/ChatScreen.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rrule/rrule.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../services/auth.dart';
import 'package:calendar_sharing/setting/color.dart' as global_colors;

class MyContent extends StatefulWidget {
  final String? cid;
  MyContent({required this.cid});

  @override
  _MyContentState createState() => _MyContentState();
}

class _MyContentState extends State<MyContent> {
  var httpClientO = null;
  var googleCalendarApiO = null;
  List<Appointment> events = [];

  @override
  void initState() {
    super.initState();
    _getCalendar();
  }

  Future<void> _getCalendar() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    events = await GetMyContentsSchedule().getMyContentsSchedule(uid,widget.cid, '2024-01-00', '2025-12-11');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    GoogleSignIn? gUser = Provider.of<UserData>(context).googleUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Calendar & Chat'),
      ),
      body:
          // Google Calendar Screen
          SfCalendar(
            view: CalendarView.week,
            timeZone: 'Japan',
            headerHeight: 50,
            dataSource: MeetingDataSource(events),
            headerDateFormat: 'yyyy MMMM',
            selectionDecoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: Colors.transparent,
                width: 0,
              ),
            ),
            appointmentBuilder:
                (BuildContext context, CalendarAppointmentDetails details) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: global_colors.Calendar_outline_color,
                    width: 3.0,
                  ),
                ),
              );
            },
            cellBorderColor: global_colors.Calendar_grid_color,
            timeSlotViewSettings: TimeSlotViewSettings(
              timeFormat: 'H:mm',
            ),
          )
    );
  }
}
class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}