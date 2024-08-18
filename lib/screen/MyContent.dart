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
  final String? calendarId;
  MyContent({required this.calendarId});

  @override
  _MyContentState createState() => _MyContentState();
}

class _MyContentState extends State<MyContent> {
  var httpClientO = null;
  var googleCalendarApiO = null;
  List<cal.Event> _events = [];
  final AuthService _auth = AuthService();
  final PageController _pageController = PageController(initialPage: 0);
  bool _showFab = true;  // Flag to control the visibility of the FloatingActionButton

  List<TimeRegion> GroupCal = []; // Initialize the list as empty

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    GoogleSignIn? gUser = Provider.of<UserData>(context).googleUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Calendar & Chat'),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _showFab = index == 0;  // Show the FAB only on the calendar page
          });
        },
        children: [
          // Google Calendar Screen
          SfCalendar(
            view: CalendarView.week,
            timeZone: 'Japan',
            headerHeight: 50,
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
            specialRegions: GroupCal,  // Use the initialized list here
          ),
        ],
      ),
    );
  }
}