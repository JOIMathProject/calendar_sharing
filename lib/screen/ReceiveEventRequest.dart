import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        backgroundColor: GlobalColor.AppBarCol,
        title: Text("イベントリクエスト"),
      ),
      body:
      widget.eventReq.length == 0 ?
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Center the content within the Row
                children: [
                  Icon(
                    Icons.info_outlined,
                    size: 35,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '表示できる情報がありません',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          :
      ListView.builder(
        itemCount: widget.eventReq.length,
        itemBuilder: (context, index) {
          final request = widget.eventReq[index];
          return Card(
            color: GlobalColor.MainCol,
            margin: EdgeInsets.all(8.0),
              child:Container(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Add margin for spacing around the tile
                padding: EdgeInsets.all(12), // Add padding inside the tile
                decoration: BoxDecoration(
                  color: GlobalColor.MainCol, // Background color for the tile
                  borderRadius: BorderRadius.circular(8), // Rounded corners like a ListTile

                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
                  children: [
                    // User icon at the top left
                    CircleAvatar(
                      backgroundImage: NetworkImage('https://calendar-files.woody1227.com/user_icon/${request.uicon}'),
                    ),
                    SizedBox(width: 12), // Space between the icon and the content

                    // Main content (title, summary, time, buttons)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title (username)
                          Text(
                            request.uname + '　からのリクエスト',
                            style: TextStyle(color: GlobalColor.SubCol, fontWeight: FontWeight.bold),
                          ),

                          // Summary below title
                          Text(
                            request.summary,
                            style: TextStyle(color: GlobalColor.SubCol),
                          ),

                          SizedBox(height: 4), // Space between summary and time

                          // Time below summary
                          Text(
                            "${DateFormat('yyyy-MM-dd HH:mm').format(request.startTime)} - ${DateFormat('yyyy-MM-dd HH:mm').format(request.endTime)}",
                            style: TextStyle(fontSize: 12, color: GlobalColor.SubCol),
                          ),

                          SizedBox(height: 8), // Space between time and buttons

                          // Buttons aligned to the right bottom
                          Align(
                            alignment: Alignment.centerRight, // Align buttons to the right
                            child: Row(
                              mainAxisSize: MainAxisSize.min, // Keep row width minimal
                              children: [
                                ElevatedButton(
                                  onPressed: () => _acceptRequest(request),
                                  child: Text("承認", style: TextStyle(color: GlobalColor.MainCol)),
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all<Color>(GlobalColor.SubCol),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _denyRequest(request),
                                  child: Text("拒否", style: TextStyle(color: GlobalColor.MainCol)),
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all<Color>(GlobalColor.SubCol),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )





          );
        },
      ),
    );
  }
}
