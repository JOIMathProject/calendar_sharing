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

class Home extends StatefulWidget {
  final String? groupId;
  final String? groupName;
  final bool startOnChatScreen;
  final bool firstVisit;
  bool is_frined;

  Home(
      {required this.groupId,
      required this.groupName,
      required this.firstVisit,
      required this.is_frined,
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

  bool flipped = false;
  List<Appointment> FrontCalendar = [];
  List<Appointment> BackCalendar = [];

  List<MyContentsInformation> _MyContents = [];
  List<CalendarInformation> _MyCalendar = [];
  MyContentsInformation? selectedContent;
  CalendarInformation? selectedCalendar;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: widget.startOnChatScreen ? 1 : 0);
    _currentPage = widget.startOnChatScreen ? 1 : 0;
    _showFab = !widget.startOnChatScreen;
    _MyCalendar = Provider.of<UserData>(context, listen: false).MyCalendar;
    _MyContents =
        Provider.of<UserData>(context, listen: false).MyContentsChoice;

    _getReceivedEvent();
    _initializeData();
    _getGroupCal();
    _getCalendar();
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
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    await _getMyContents(Provider.of<UserData>(context, listen: false).uid);
    if (widget.firstVisit) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showFirstVisitDialog());
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

  Future<void> _addCalendarToGroup(
      String gid, String? uid, String calendar_id) async {
    await SetGroupPrimaryCalendar()
        .setGroupPrimaryCalendar(gid, uid, calendar_id);
  }

  void _showFirstVisitDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dialog from being dismissed by touching outside
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
                title: Text('カレンダーと\nコンテンツを選択'),
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
                            setState(() {
                              selectedContent = newValue;
                            });
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
                        onChanged: (CalendarInformation? newValue) async {
                          if (newValue != null) {
                            setState(() {
                              selectedCalendar = newValue;
                            });
                          }
                        },
                      ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('キャンセル'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                      child: Text('登録'),
                      onPressed: () async {
                        if (selectedContent?.cname != 'なし') {
                          await _addContentToGroup(
                              widget.groupId!, selectedContent!.cid);
                        }
                        await _addCalendarToGroup(
                          widget.groupId!,
                          Provider.of<UserData>(context, listen: false).uid,
                          selectedCalendar!.calendar_id,
                        );
                        await SetOpened().setOpened(
                            Provider.of<UserData>(context, listen: false).uid,
                            widget.groupId!);
                        Navigator.of(context).pop();
                      }),
                ],
              );
            },
          ),
        );
      },
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
                  uid, content.cid, '2024-01-00', '2025-12-11');
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
        title: Text(widget.groupName!,
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
                  if (details.appointments != null &&
                      details.appointments!.isNotEmpty) {
                    final Appointment appointment = details.appointments!.first;
                    print(
                        "Tapped appointment: ${appointment.subject}, Notes: ${appointment.notes}"); // Debugging

                    if (flipped) {
                      // Logic for when _isFlipped is true
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(appointment.subject),
                            content: Text(
                              (appointment.notes == null ||
                                      appointment.notes!.isEmpty)
                                  ? '概要なし' // 'No summary' in Japanese
                                  : appointment.notes!,
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('閉じる'), // 'Close' in Japanese
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // Logic for when _isFlipped is false
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                '予定あり'), // 'Appointment exists' in Japanese
                            content: SingleChildScrollView(
                              child: Column(
                                children:
                                    appointment.subject.split('\n').map((line) {
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
                              ),
                            ),
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
                  } else {
                    print(
                        "Tapped on a non-appointment area or no appointments present."); // Debugging
                  }
                },
              ),
              ChatScreen(gid: widget.groupId),
            ],
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
                        Icon(Icons.flip, color: GlobalColor.SubCol, size: 30),
                    tooltip: 'Flip Events',
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
                    tooltip: 'Search Schedule',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _getGroupCal() async {
    var fetchedRegions = await GetGroupCalendar()
        .getGroupCalendar(widget.groupId, '2023-01-00', '2025-12-11');
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
