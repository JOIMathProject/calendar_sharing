import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import '../setting/color.dart' as GlobalColor;

class ReceiveEventrequest extends StatefulWidget {
  final List<eventRequest> eventReq;
  final String? gid;
  final MyContentsInformation? usedContent;
  ReceiveEventrequest({required this.eventReq
    , required this.gid
   , required this.usedContent});

  @override
  _receivedEventRequest createState() => _receivedEventRequest();
}

class _receivedEventRequest extends State<ReceiveEventrequest> {
  String? uid;
  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserData>(context, listen: false).uid;
  }

  void _acceptRequest(eventRequest request) {
    ReceiveEventRequest().receiveEventRequest(uid, request.uid, widget.gid, request.event_request_id, 'calendar_id');
    print("Accepted request from ${request.uname}");
  }

  void _denyRequest(eventRequest request) {
    RejectEventRequest().rejectEventRequest(uid, request.uid, widget.gid, request.event_request_id);
    print("Denied request from ${request.uname}");
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserUid = Provider.of<UserData>(context, listen: false).uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
        title: Text("イベントリクエスト"),
      ),
      body: ListView.builder(
        itemCount: widget.eventReq.length,
        itemBuilder: (context, index) {
          final request = widget.eventReq[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(request.uicon),
              ),
              title: Text(request.uname),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.summary),
                  Text(
                    "${request.startTime} - ${request.endTime}",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    child: Text("Accept"),

                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _denyRequest(request),
                    child: Text("Deny"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
