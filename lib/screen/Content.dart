import 'dart:async';
import 'dart:convert';
import 'package:badges/badges.dart';
import 'package:calendar_sharing/screen/ChatScreen.dart';
import 'package:calendar_sharing/screen/ContentsSetting.dart';
import 'package:calendar_sharing/screen/ReceiveEventRequest.dart';
import 'package:calendar_sharing/screen/SearchSchedule.dart';
import 'package:calendar_sharing/screen/friendContentsSetting.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as ggl;
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../services/auth.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:badges/badges.dart' as badge;
import 'package:intl/intl.dart';

import 'FirstVisitScreen.dart';

class Home extends StatefulWidget {
  final String? groupId;
  final bool startOnChatScreen;
  final bool firstVisit;
  final String groupName;
  bool is_frined;

  Home(
      {required this.groupId,
      required this.firstVisit,
      required this.is_frined,
      required this.groupName,
      this.startOnChatScreen = false});

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
  int unreadMessageCount = 0;
  bool flipped = false;
  List<Appointment> FrontCalendar = [];
  List<Appointment> BackCalendar = [];
  String groupName = '';
  List<MyContentsInformation> _MyContents = [];
  List<CalendarInformation> _MyCalendar = [];
  MyContentsInformation? selectedContent;
  CalendarInformation? selectedCalendar;


  DateTime currentDate = DateTime.now();

  DateTime startDate = DateTime(2024, 01, 01);

  DateTime endDate = DateTime(2025, 01, 01);
  String formattedStartDate = '2024-01-01';
  String formattedEndDate = '2025-01-01';
  bool loading = true;
  @override
  void initState() {
    super.initState();
    startDate = DateTime(currentDate.year, currentDate.month - 3, currentDate.day);
    endDate = DateTime(currentDate.year, currentDate.month + 6, currentDate.day);

    formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
    _pageController =
        PageController(initialPage: widget.startOnChatScreen ? 1 : 0);
    _currentPage = widget.startOnChatScreen ? 1 : 0;
    _showFab = !widget.startOnChatScreen;
    _MyCalendar = Provider.of<UserData>(context, listen: false).MyCalendar;
    _MyContents =
        Provider.of<UserData>(context, listen: false).MyContentsChoice;

    if (widget.firstVisit) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showFirstVisitDialog());
    }
    _initializeData();
  }
  Future<void> _initializeData() async {
    setState(() {
      loading = true; // Show loading indicator
    });

    try {
      // Await all asynchronous operations concurrently
      await Future.wait([
        _getName(),
        _getReceivedEvent(),
        _getMyContents(),
        _getGroupCal(),
        _getCalendar(),
        _getChatUnread(),
      ]);
    } catch (e) {
      // Handle any errors that occur during the async operations
      print("Error initializing data: $e");
      // Optionally, you can set an error state here to display an error message to the user
    } finally {
      setState(() {
        loading = false; // Hide loading indicator after all operations are complete
      });
    }

    // Start periodic updates after initial data fetch
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
      }
      if (!flipped) {
        FrontCalendar = GroupCal;
        BackCalendar = _events;
      } else {
        FrontCalendar = _events;
        BackCalendar = GroupCal;
      }
      _getReceivedEvent();
      _getGroupCal();
      _getCalendar();
      _getChatUnread();
      _getName();
      setState(() {});
    });
  }


  Future<void> _getChatUnread() async{
    unreadMessageCount = await UnreadMessage().unreadMessage(Provider.of<UserData>(context, listen: false).uid!,widget.groupId);
  }
  Future<void> _getMyContents() async {
    usedContent = await _getCurrentUserContent(widget.groupId!, Provider.of<UserData>(context, listen: false).uid!);
    selectedContent = _MyContents.isNotEmpty ? _MyContents[0] : null;
    selectedCalendar = _MyCalendar.isNotEmpty ? _MyCalendar[0] : null;
    if (mounted) {
      setState(() {});
    }
  }
  void _showFirstVisitDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return FirstVisitScreen(
            groupId: widget.groupId!,
            isFriend: widget.is_frined,
          );
        },
      ),
    );
  }
  Future<MyContentsInformation?> _getCurrentUserContent(
      String gid, String uid) async {
    List<ContentsInformation>? contents =
        await GetContentInGroup().getContentInGroup(gid);
    if (contents?.isNotEmpty == true) {
      return _MyContents.firstWhere(
        (content) => contents!.any((groupContent) =>
            groupContent.uid == uid && content.cid == groupContent.cid),
        orElse: () => _MyContents[0],
      );
    }
    return _MyContents[0];
  }
  Future<void> _getName() async {
    groupName = await GetGroupName().getGroupName(widget.groupId);
    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _getCalendar() async {
    List<ContentsInformation>? contents =
        await GetContentInGroup().getContentInGroup(widget.groupId);
    String? uid = Provider.of<UserData>(context, listen: false).uid;
    if (contents?.isNotEmpty == true) {
      for (var content in contents!) {
        if (content.uid == uid) {
          List<eventInformation> eventsCollection = [];
          eventsCollection = await GetMyContentsSchedule()
              .getMyContentsSchedule(
                  uid, content.cid, formattedStartDate, formattedEndDate);
          List<Appointment> fetchedAppointments = [];
          for (var event in eventsCollection) {
            fetchedAppointments.add(Appointment(
              startTime: event.startTime,
              endTime: event.endTime,
              subject: event.summary,
              notes: event.description, // Map description to notes
              color: event.is_local
                  ? Colors.blue
                  : GlobalColor.MyCalCol, // Different colors
            ));
          }
          _events = fetchedAppointments;
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _getReceivedEvent() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;

    try {
      List<eventRequest>? requests =
          await GetEventRequest().getEventRequest(uid, widget.groupId);
      if (requests?.isNotEmpty == true) {
        _requests = requests;
      } else {
        _requests = [];
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        _requests = [];
      } else {
        print("Error occurred: $e");
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.is_frined?widget.groupName:groupName,
            style: TextStyle(fontFamily: 'MPLUSRounded1c-Medium')),
        backgroundColor: GlobalColor.AppBarCol,
        actions: [
          badge.Badge(
            showBadge: _requests.isNotEmpty,
            position: BadgePosition.topEnd(top: 10, end: 10),
            child: IconButton(
              icon: Icon(Icons.notifications, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiveEventrequest(
                      eventReq: _requests,
                      gid: widget.groupId,
                      usedContent: usedContent,
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: _currentPage == 0
                ? badge.Badge(
              position: badge.BadgePosition.topEnd(top: -6, end: -2),
              badgeStyle: badge.BadgeStyle(
                badgeColor: Colors.red, // Set your desired badge color
                padding: EdgeInsets.all(5),
              ),
              badgeContent: Text(
                unreadMessageCount.toString(),
                style: TextStyle(
                  color: GlobalColor.SubCol,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              showBadge: unreadMessageCount > 0,
              child: Icon(
                Icons.chat,
                size: 30,
              ),
            )
                : Icon(
              Icons.calendar_today,
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
                  builder: (context) => !widget.is_frined
                      ? ContentsSetting(
                          groupId: widget.groupId,
                          usedCalendar: usedContent,
                        )
                      : friendContentsSetting(
                          groupId: widget.groupId, usedCalendar: usedContent),
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
                dataSource: MeetingDataSource(FrontCalendar),
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
                    child: flipped ? Center(
                      child: Text(
                        appointment.subject,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Colors.white, // Adjust based on background color
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.fade,
                      ),
                    ): SizedBox.shrink(),
                  );
                },
                specialRegions: getAppointments(BackCalendar),
                onTap: (CalendarTapDetails details) {
                  // Check if there are appointments tapped
                  if (details.appointments != null && details.appointments!.isNotEmpty) {
                    final Appointment appointment = details.appointments!.first;
                    print(
                        "Tapped appointment: ${appointment.subject}, Notes: ${appointment.notes}"); // Debugging

                    if (flipped) {
                      // Logic for when _isFlipped is true
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: GlobalColor.SubCol,
                        isScrollControlled: true, // Allows better control over modal height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (BuildContext context) {
                          return Container(
                            width: double.infinity, // Set the width to the full available width
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Keep the height as per content
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  appointment.subject,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  (appointment.notes == null || appointment.notes!.isEmpty)
                                      ? '概要なし' // 'No summary' in Japanese
                                      : appointment.notes!,
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          );
                        },
                      );
                    } else {
                      // Logic for when _isFlipped is false
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: GlobalColor.SubCol,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (BuildContext context) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '予定あり',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,),
                                  ),
                                  SizedBox(height: 16),
                                  ...appointment.subject.split('\n').map((line) {
                                    List<String> parts = line.split(' - ');
                                    if (parts.length == 2) {
                                      String uicon = parts[0].trim();
                                      String uname = parts[1].trim();
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            "https://calendar-files.woody1227.com/user_icon/$uicon",
                                          ),
                                        ),
                                        title: Text(uname),
                                      );
                                    } else {
                                      // Handle lines that don't match the expected format
                                      return SizedBox.shrink();
                                    }
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  } else {
                    print("Tapped on a non-appointment area or no appointments present."); // Debugging
                  }
                },
              ),
                ChatScreen(gid: widget.groupId),
            ],
          ),
          if (loading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(GlobalColor.MainCol),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // **New Floating Action Button for Flipping Events**
                  FloatingActionButton(
                    heroTag: 'flipButton', // Unique hero tag
                    backgroundColor: GlobalColor.MainCol,
                    onPressed: () {
                      setState(() {
                        flipped = !flipped;
                        print("Flip button pressed. _isFlipped: $flipped");
                        if (!flipped) {
                          FrontCalendar = GroupCal;
                          BackCalendar = _events;
                        } else {
                          FrontCalendar = _events;
                          BackCalendar = GroupCal;
                        }
                      });
                    },
                    child:
                        Icon(Icons.autorenew, color: GlobalColor.SubCol, size: 30),
                    tooltip: 'イベント表示を切り替える',
                  ),
                  SizedBox(width: 16), // Spacing between FABs
                  // **Existing Floating Action Button for Search**
                  FloatingActionButton(
                    heroTag: 'searchButton', // Unique hero tag
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
                    child:
                        Icon(Icons.search, color: GlobalColor.SubCol, size: 30),
                    tooltip: '予定を検索',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _getGroupCal() async {
    var fetchedRegions = await GetGroupCalendar()
        .getGroupCalendar(widget.groupId, formattedStartDate, formattedEndDate);
    setState(() {
      GroupCal = fetchedRegions;
    });
  }

  List<TimeRegion> getAppointments(List<Appointment> events) {
    List<TimeRegion> meetings = <TimeRegion>[];
    for (var event in events) {
      if (event.startTime == null || event.endTime == null) continue;
      meetings.add(TimeRegion(
        startTime: event.startTime,
        endTime: event.endTime,
        color: event.color,
        //color: GlobalColor.Calendar_outline_color,
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
