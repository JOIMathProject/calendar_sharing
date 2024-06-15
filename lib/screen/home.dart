import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/chat/v1.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../services/auth.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<cal.Event> _events = [];
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _getCalendarEvents();
  }

  void prompt(String url) {
    print("Please go to the following URL and grant access:");
    print("  => $url");
    print("");
  }

  Future<void> _getCalendarEvents() async {
    var _clientID = ClientId('213698548031-3d7imnc8dnkllv68vntdgkbnotrajcnv.apps.googleusercontent.com', '');
    var _scopes = [cal.CalendarApi.calendarScope];
    await clientViaUserConsent(_clientID, _scopes, prompt)
        .then((AuthClient client) {
      var calendar = cal.CalendarApi(client);
      calendar.events.list('primary', singleEvents: true).then((value) {
        setState(() {
          _events = value.items!;
        });
      });
    });
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
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: SfCalendar(
        view: CalendarView.month,
        dataSource: _getCalendarDataSource(),
      ),
    );
  }

  _getCalendarDataSource() {
    List<Appointment> appointments = <Appointment>[];
    for (var event in _events) {
      DateTime start = event.start!.dateTime!.toLocal();
      DateTime end = event.end!.dateTime!.toLocal();
      appointments.add(Appointment(
        startTime: start,
        endTime: end,
        subject: event.summary!,
        color: Colors.blue,
      ));
    }
    return _AppointmentDataSource(appointments);
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
