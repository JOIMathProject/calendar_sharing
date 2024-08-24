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

class Home extends StatefulWidget {
  final String? groupId;
  final String? groupName;
  final bool startOnChatScreen;

  Home({required this.groupId, required this.groupName, this.startOnChatScreen = false});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var httpClientO = null;
  var googleCalendarApiO = null;
  List<cal.Event> _events = [];
  final AuthService _auth = AuthService();
  late PageController _pageController;
  bool _showFab = true;
  int _currentPage = 0; // To track the current page

  List<TimeRegion> GroupCal = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.startOnChatScreen ? 1 : 0);
    _currentPage = widget.startOnChatScreen ? 1 : 0;
    _showFab = !widget.startOnChatScreen;
    _getTimeRegions();
  }

  Future<void> _getSelfCalendarEvents(GoogleSignIn? gUser) async {
    if (gUser == null) return;
    try {
      httpClientO = (await gUser?.authenticatedClient())!;
    } catch (e) {
      print(e.toString());
      await _auth.signOut(context);
      return;
    }
    googleCalendarApiO = cal.CalendarApi(httpClientO);
    String calenderId = "primary";
    DateTime timeMin = DateTime(2000, 4, 1);
    DateTime timeMax = DateTime(2100, 12, 31);
    try {
      var events = await googleCalendarApiO.events.list(calenderId,
          timeMin: timeMin, timeMax: timeMax, maxResults: 2500);
      if (events.items != null && events.items!.isNotEmpty) {
        setState(() {
          _events = events.items!;
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    GoogleSignIn? gUser = Provider.of<UserData>(context).googleUser;
    _getSelfCalendarEvents(gUser);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName!),
        actions: [
          IconButton(
            icon: Icon(
              _currentPage == 0 ? Icons.chat : Icons.calendar_today, // Change icon based on page
              size: 30,
            ),
            onPressed: () {
              if (_currentPage == 0) {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              size: 30,
            ),
            onPressed: () {
              // Implement settings functionality here
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                _showFab = index == 0;
              });
            },
            children: [
              SfCalendar(
                view: CalendarView.week,
                timeZone: 'Japan',
                headerHeight: 50,
                dataSource: MeetingDataSource(getAppointments()),
                headerDateFormat: 'yyyy MMMM',
                selectionDecoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.transparent,
                    width: 0,
                  ),
                ),
                appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
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
                specialRegions: GroupCal,
              ),
              ChatScreen(gid: widget.groupId),
            ],
          ),
          //if (!_showFab)
          //  Align(
          //    alignment: Alignment.bottomRight,
          //    child: Padding(
          //      padding: const EdgeInsets.only(bottom: 100.0, right: 16),
          //      child: FloatingActionButton(
          //        onPressed: () {
          //          _pageController.previousPage(
          //              duration: Duration(milliseconds: 300),
          //              curve: Curves.easeInOut);
          //        },
          //        child: Icon(Icons.calendar_today),
          //      ),
          //    ),
          //  ),
        ],
      ),
      //floatingActionButton: _showFab
      //    ? FloatingActionButton(
      //  onPressed: () {
      //    _pageController.nextPage(
      //        duration: Duration(milliseconds: 300),
      //        curve: Curves.easeInOut);
      //  },
      //  child: Icon(Icons.message),
      //)
      //    : null,
    );
  }

  Future<void> _getTimeRegions() async {
    var fetchedRegions = await GetGroupCalendar().getGroupCalendar(widget.groupId, '2023-01-00', '2025-12-11');
    setState(() {
      GroupCal = fetchedRegions;
    });
  }

  List<Appointment> getAppointments() {
    List<Appointment> meetings = <Appointment>[];
    for (var event in _events) {
      if (event.start?.dateTime == null || event.end?.dateTime == null) continue;

      if (event.recurrence != null && event.recurrence!.isNotEmpty) {
        String rruleString = event.recurrence![0];
        rruleString = rruleString.replaceAll('WKST=SU', 'WKST=MO');
        RecurrenceRule rrule = RecurrenceRule.fromString(rruleString);

        List<DateTime> recurringDates = rrule.getAllInstances(
          start: event.start!.dateTime!,
          before: rrule.until == null
              ? event.start!.dateTime!.add(Duration(days: 365))
              : rrule.until,
        );

        for (DateTime date in recurringDates) {
          meetings.add(Appointment(
            startTime: date,
            endTime: date.add(event.end!.dateTime!.difference(event.start!.dateTime!)),
            color: global_colors.Calendar_icon_color,
          ));
        }
      } else {
        meetings.add(Appointment(
          startTime: event.start!.dateTime!,
          endTime: event.end!.dateTime!,
          color: global_colors.Calendar_icon_color,
        ));
      }
    }
    return meetings;
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
