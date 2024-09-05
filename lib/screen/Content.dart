import 'dart:async';
import 'dart:convert';
import 'package:calendar_sharing/screen/ChatScreen.dart';
import 'package:calendar_sharing/screen/ContentsSetting.dart';
import 'package:calendar_sharing/screen/ReceiveEventRequest.dart';
import 'package:calendar_sharing/screen/SearchSchedule.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../services/auth.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:badges/badges.dart' as badge;

class Home extends StatefulWidget {
  final String? groupId;
  final String? groupName;
  final bool startOnChatScreen;
  final bool firstVisit;

  Home(
      {required this.groupId,
      required this.groupName,
       required this.firstVisit,

      this.startOnChatScreen = false
      });

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var httpClientO = null;
  var googleCalendarApiO = null;
  List<Appointment> _events = [];
  List<eventRequest> _requests = [];
  final AuthService _auth = AuthService();
  late PageController _pageController;
  bool _showFab = true;
  int _currentPage = 0;
  CalendarView _currentView = CalendarView.week;
  MyContentsInformation? usedContent;
  List<Appointment> GroupCal = [];


  List<MyContentsInformation> _MyContents = [];
  List<CalendarInformation> _MyCalendar = [];
  MyContentsInformation? selectedContent;
  CalendarInformation? selectedCalendar;

  @override
  void initState() {
    print('yaid');
    super.initState();
    _pageController =
        PageController(initialPage: widget.startOnChatScreen ? 1 : 0);
    _currentPage = widget.startOnChatScreen ? 1 : 0;
    _showFab = !widget.startOnChatScreen;
    _MyCalendar = Provider.of<UserData>(context, listen: false).MyCalendar;
    _MyContents = Provider.of<UserData>(context, listen: false).MyContents;
    _initializeData();
    _getTimeRegions();
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (!mounted) {
        _getReceivedEvent();
        timer.cancel();
      }
      _getCalendar();
    });
  }
  Future<void> _initializeData() async {
    await _getMyContents(Provider.of<UserData>(context, listen: false).uid);
    if (widget.firstVisit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFirstVisitDialog());
    }
  }
  Future<void> _getMyContents(String? uid) async {
    usedContent = await _getCurrentUserContent(widget.groupId!, uid!);
    selectedContent = _MyContents.isNotEmpty ? _MyContents[0] : null;
    selectedCalendar = _MyCalendar.isNotEmpty ? _MyCalendar[0] : null;
    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _addContentToGroup(String gid, String cid) async {
    await AddContentsToGroup().addContentsToGroup(gid, cid);
  }

  Future<void> _removeContentFromGroup(String gid, String cid) async {
    await RemoveContentsFromGroup().removeContentsFromGroup(gid, cid);
  }
  void _showFirstVisitDialog() {
    TextEditingController contentController = TextEditingController();
    TextEditingController calendarController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dialog from being dismissed by touching outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            return false;
          },
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Select Content and Calendar'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("表示コンテンツを選択"),
                    if (_MyContents.isNotEmpty)
                      DropdownButton<MyContentsInformation>(
                        value: selectedContent,
                        items: _MyContents.map((MyContentsInformation content) {
                          return DropdownMenuItem<MyContentsInformation>(
                            value: content,
                            child: Text(content.cname),
                          );
                        }).toList(),
                        onChanged: (MyContentsInformation? newValue) async {
                          if (newValue != null) {
                            if (selectedContent?.cid != '') {
                              await _removeContentFromGroup(widget.groupId!, selectedContent!.cid);
                            }
                            setState(() {
                              selectedContent = newValue;
                            });
                            if (newValue.cname != 'None') {
                              await _addContentToGroup(widget.groupId!, newValue.cid);
                            }
                          }
                        },
                      ),
                    SizedBox(height: 20),
                    Text("予定追加先カレンダーを選択"),
                    if (_MyCalendar.isNotEmpty)
                      DropdownButton<CalendarInformation>(
                        value: selectedCalendar,
                        items: _MyCalendar.map((CalendarInformation content) {
                          return DropdownMenuItem<CalendarInformation>(
                            value: content,
                            child: Text(content.summary),
                          );
                        }).toList(),
                        onChanged: (CalendarInformation? newValue) {
                          setState(() {
                            selectedCalendar = newValue;
                          });
                        },
                      ),
                  ],
                ),
                actions: <Widget>[TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
                  TextButton(
                    child: Text('Submit'),
                    onPressed: selectedCalendar != null
                        ? () {
                      Navigator.of(context).pop();
                    }
                        : null,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }





  Future<MyContentsInformation?> _getCurrentUserContent(String gid, String uid) async {
    List<ContentsInformation>? contents = await GetContentInGroup().getContentInGroup(gid);
    if (contents?.isNotEmpty == true) {
      return _MyContents.firstWhere(
            (content) => contents!.any((groupContent) => groupContent.uid == uid && content.cid == groupContent.cid),
        orElse: () => _MyContents[0],
      );
    }
    return _MyContents[0];
  }
  Future<void> _getCalendar() async {
    List<ContentsInformation>? contents =
        await GetContentInGroup().getContentInGroup(widget.groupId);
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    if (contents?.isNotEmpty == true) {
      for (var content in contents!) {
        if (content.uid == uid) {
          _events = await GetMyContentsSchedule().getMyContentsSchedule(
              uid, content.cid, '2024-01-00', '2025-12-11');
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _getReceivedEvent() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    List<eventRequest>? requests = await GetEventRequest().getEventRequest(uid,widget.groupId);
    if (requests?.isNotEmpty == true) {
        _requests = requests;
    }
    if (mounted) {
      setState(() {});
    }
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
          badge.Badge(
            showBadge: _requests.isNotEmpty,
            badgeContent: Text(""),
            child: IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiveEventrequest(eventReq: _requests,
                      gid: widget.groupId,usedContent: usedContent,),
                  ),
                );
              },
            ),
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
                    usedCalendar: usedContent,
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
                  allowedViews: <CalendarView>
                  [
                    CalendarView.day,
                    CalendarView.week,
                  ],
                  timeZone: 'Japan',
                  headerHeight: 50,
                  dataSource: MeetingDataSource(GroupCal),
                  showDatePickerButton: true,
                  showWeekNumber: true,
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
                        borderRadius: BorderRadius.circular(0),
                        color: appointment.color,
                      ),
                    );
                  },
                  specialRegions: getAppointments(),
                  onTap: (CalendarTapDetails details) {
                    if (details.targetElement == CalendarElement.appointment) {
                      final Appointment appointment =
                          details.appointments!.first;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('参加メンバー'),
                            content: Text(appointment.subject),
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
                  }),
              ChatScreen(gid: widget.groupId),
            ],
          ),
        ],
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              backgroundColor: GlobalColor.MainCol,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchSchedule(
                      groupId: widget.groupId,
                    ),
                  ),
                );
              },
              child: Icon(Icons.search, color: GlobalColor.SubCol, size: 30),
            )
          : null,
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
