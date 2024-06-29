import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rrule/rrule.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../services/auth.dart';

class Home extends StatefulWidget {


  final GoogleSignIn? gUser;
  Home({required this.gUser});

@override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var httpClientO = null;
  var googleCalendarApiO = null;
  List<cal.Event> _events = [];
  final AuthService _auth = AuthService();

  final CalendarController _calendarController = CalendarController();

  @override
  void initState(){
    super.initState();
    _getCalendarEvents();
  }
  Future<void> _getCalendarEvents() async {
    if(widget.gUser == null) return;
    try{
      httpClientO = (await widget.gUser?.authenticatedClient())!;
    }catch(e){
      print(e.toString());
      await _auth.signOut(context);
      return;
    }
    googleCalendarApiO = cal.CalendarApi(httpClientO);

    String calenderId = "primary";

    // Set timeMin to a date far in the past and timeMax to a date far in the future
    DateTime timeMin = DateTime(2000, 4, 1);
    DateTime timeMax = DateTime(2100, 12, 31);

    try{
      var events = await googleCalendarApiO.events.list(calenderId, timeMin: timeMin, timeMax: timeMax,maxResults: 2500);
      if(events.items != null && events.items!.isNotEmpty){
        setState(() {
          _events = events.items!;
        });
      }
    }catch(e){
      print(e.toString());
    }
    //print all the event's list
    for (var event in _events) {
      //print(event.start!.dateTime);
    }
    if (_events == null) {
      print('_events is null');
    } else {
      print('Number of events: ${_events.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Calendar Events'),
        actions: <Widget>[
          ElevatedButton.icon(
            icon: Icon(Icons.person),
            label: Text('logout'),
            onPressed: () async {
              await _auth.signOut(context);
            },
          ),
        ],
      ),
      body: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: _getCalendarEvents,
              child: Text('Fetch Calendar Events'),
            ),
            Expanded(
              child:Stack(
                children: <Widget>[
                  SfCalendar(
                    view: CalendarView.week,
                    dataSource: MeetingDataSource(getAppointments()),
                    controller: _calendarController, // Assign the controller
                    appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
                      return Container(
                        width: details.bounds.width,
                        height: details.bounds.height,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                        ),
                      );
                    },
                    selectionDecoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.transparent,
                        width: 0,
                      ),
                    ),
                    todayHighlightColor: Colors.transparent,
                    todayTextStyle: TextStyle(
                      color: Colors.transparent, // Set the today text color to transparent
                    ),
                    cellBorderColor: Colors.transparent,
                    timeSlotViewSettings: TimeSlotViewSettings(
                      timeInterval: Duration(hours: 2),
                      timeTextStyle: TextStyle(
                        color: Colors.transparent, // Set the time text color to transparent
                      ),
                    ),
                    headerStyle: CalendarHeaderStyle(
                      textAlign: TextAlign.left,
                      textStyle: TextStyle(
                        color: Colors.transparent, // Set the text color to transparent
                      ),
                    ),
                    viewHeaderStyle: ViewHeaderStyle(
                      dateTextStyle: TextStyle(
                        color: Colors.transparent, // Set the date text color to transparent
                      ),
                      dayTextStyle: TextStyle(
                        color: Colors.transparent, // Set the day text color to transparent
                      ),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: true,
                    child:SfCalendar(
                      view: CalendarView.week,
                      dataSource: MeetingDataSource(getAppointments()),
                      controller: _calendarController,

                      selectionDecoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ),
                      timeSlotViewSettings: TimeSlotViewSettings(
                        timeInterval: Duration(hours: 2),
                      ),
                    )
                  ),
                ],
              ),
            ),
          ]
      ),
    );
  }
  List<Appointment> getAppointments(){
    List<Appointment> meetings = <Appointment>[];
    for (var event in _events) {
      if(event.start?.dateTime == null || event.end?.dateTime == null) continue;

      // Check if the event is a recurring event
      if (event.recurrence != null && event.recurrence!.isNotEmpty) {
        // Parse the recurrence rule
        String rruleString = event.recurrence![0];

        // Replace WKST=SU with WKST=MO
        rruleString = rruleString.replaceAll('WKST=SU', 'WKST=MO');

        RecurrenceRule rrule = RecurrenceRule.fromString(rruleString);

        // Generate the recurring dates
        List<DateTime> recurringDates = rrule.getAllInstances(
          start: event.start!.dateTime!,
          before: rrule.until == null ? event.start!.dateTime!.add(Duration(days: 365)) : rrule.until,
        );

        // Create an appointment for each recurring date
        for (DateTime date in recurringDates) {
          meetings.add(Appointment(
            startTime: date,
            endTime: date.add(event.end!.dateTime!.difference(event.start!.dateTime!)),
            color: Color(0x2800FF70),
          ));
        }
      } else {
        // If the event is not a recurring event, add it as a single appointment
        meetings.add(Appointment(
          startTime: event.start!.dateTime!,
          endTime: event.end!.dateTime!,
          color: Colors.blue,
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
