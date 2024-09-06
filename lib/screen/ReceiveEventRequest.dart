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
  String? primaryCalendar;
  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserData>(context, listen: false).uid;
  }
  Future<void> getPrimaryCalendar() async {
    primaryCalendar = await GetGroupPrimaryCalendar().getGroupPrimaryCalendar(widget.gid,uid);
  }
  Future<void> _acceptRequest(eventRequest request) async {
    await getPrimaryCalendar();
    print('uid: $uid gid: ${widget.gid} request: ${request.uid} ${request.event_request_id} ${primaryCalendar}');
    ReceiveEventRequest().receiveEventRequest(uid, request.uid, widget.gid, request.event_request_id,primaryCalendar );
    widget.eventReq.remove(request);
    print("Accepted request from ${request.uname}");
    setState(() {
    });
  }

  void _denyRequest(eventRequest request) {
    RejectEventRequest().rejectEventRequest(uid, request.uid, widget.gid, request.event_request_id);
    print("Denied request from ${request.uname}");
    widget.eventReq.remove(request);
    setState(() {
    });
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
                backgroundImage: NetworkImage('https://calendar-files.woody1227.com/user_icon/${request.uicon}'),
              ),
              title: Text(request.uname, style: TextStyle(color: GlobalColor.SubCol)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.summary, style: TextStyle(color: GlobalColor.SubCol)),
                  Text(
                    "${request.startTime} - ${request.endTime}",
                    style: TextStyle(fontSize: 12, color: GlobalColor.SubCol),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    child: Text("Accept", style: TextStyle(color: GlobalColor.MainCol)),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(GlobalColor.SubCol),
                    )
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _denyRequest(request),
                    child: Text("Deny", style: TextStyle(color: GlobalColor.MainCol)),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(GlobalColor.SubCol),
                      )
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
