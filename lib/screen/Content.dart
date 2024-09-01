import 'dart:convert';
import 'package:calendar_sharing/screen/ChatScreen.dart';
import 'package:calendar_sharing/screen/ContentsSetting.dart';
import 'package:calendar_sharing/screen/SearchSchedule.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/admob/v1.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rrule/rrule.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../services/auth.dart';
import '../setting/color.dart' as GlobalColor;
import 'dart:ui' as ui;

class Home extends StatefulWidget {
  final String? groupId;
  final String? groupName;
  final bool startOnChatScreen;

  Home(
      {required this.groupId,
      required this.groupName,
      this.startOnChatScreen = false});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var httpClientO = null;
  var googleCalendarApiO = null;
  List<Appointment> _events = [];
  final AuthService _auth = AuthService();
  late PageController _pageController;
  bool _showFab = true;
  int _currentPage = 0;
  CalendarView _currentView = CalendarView.week;

  List<Appointment> GroupCal = [];

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: widget.startOnChatScreen ? 1 : 0);
    _currentPage = widget.startOnChatScreen ? 1 : 0;
    _showFab = !widget.startOnChatScreen;
    _getTimeRegions();
    _getCalendar();
  }
  Future<void> _getCalendar() async {
    List<ContentsInformation>? contents = await GetContentInGroup().getContentInGroup(widget.groupId);
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    if (contents?.isNotEmpty == true) {
      for (var content in contents!) {
        if(content.uid == uid){
          _events = await GetMyContentsSchedule().getMyContentsSchedule(uid, content.cid, '2024-01-00', '2025-12-11');
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName!),
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
          IconButton(
            icon: Icon(
              _currentPage == 0
                  ? Icons.chat
                  : Icons.calendar_today, // Change icon based on page
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContentsSetting(
                    groupId: widget.groupId,
                  ),
                ),
              );
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
                key: ValueKey(_currentView),
                view: _currentView,
                timeZone: 'Japan',
                headerHeight: 50,
                dataSource: MeetingDataSource(GroupCal),
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
                specialRegions: getAppointments(),
              ),
              ChatScreen(gid: widget.groupId),
            ],
          ),
        ],
      ),
      floatingActionButton: _showFab ? FloatingActionButton(
              backgroundColor: GlobalColor.MainCol,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchSchedule(groupId: widget.groupId,),
                  ),
                );
              },
              child: Icon(Icons.search, color: GlobalColor.SubCol, size: 30),
            ): null,
    );
  }

  Future<void> _getTimeRegions() async {
    var fetchedRegions = await GetGroupCalendar()
        .getGroupCalendar(widget.groupId, '2023-01-00', '2025-12-11');
    setState(() {
      GroupCal = fetchedRegions;
    });
  }

  List<TimeRegion> getAppointments() {
    List<TimeRegion> meetings = <TimeRegion>[];
    for (var event in _events) {
      if (event.startTime == null || event.endTime == null) continue;
        meetings.add(TimeRegion(
          startTime: event.startTime,
          endTime: event.endTime,
          color: GlobalColor.Calendar_outline_color,
        ));
      }
    return meetings;
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
