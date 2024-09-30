import 'dart:async';

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
  List<eventRequest> _requests = [];
  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserData>(context, listen: false).uid;
    _requests = widget.eventReq;
    _getReceivedEvent();

    Timer.periodic(Duration(seconds: 5), (timer) {
      _getReceivedEvent();
    });
  }
  Future<void> _getReceivedEvent() async {
    String? uid = Provider.of<UserData>(context, listen: false).uid;

    try {
      List<eventRequest>? requests =
      await GetEventRequest().getEventRequest(uid, widget.gid);
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
  Future<void> getPrimaryCalendar() async {
    primaryCalendar = await GetGroupPrimaryCalendar().getGroupPrimaryCalendar(widget.gid,uid);
  }
  Future<void> _acceptRequest(eventRequest request) async {
    await getPrimaryCalendar();
    print('uid: $uid gid: ${widget.gid} request: ${request.uid} ${request.event_request_id} ${primaryCalendar}');
    ReceiveEventRequest().receiveEventRequest(uid, request.uid, widget.gid, request.event_request_id,primaryCalendar );
    _requests.remove(request);
    print("Accepted request from ${request.uname}");
    setState(() {
    });
  }

  void _denyRequest(eventRequest request) {
    RejectEventRequest().rejectEventRequest(uid, request.uid, widget.gid, request.event_request_id);
    print("Denied request from ${request.uname}");
    _requests.remove(request);
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
      body: RefreshIndicator(
        onRefresh: _getReceivedEvent,
        child: _requests.isEmpty
            ? ListView(
          // Ensures the child is scrollable
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8, // Provides enough space to allow pull-to-refresh
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ],
        )
            : ListView.builder(
          itemCount: _requests.length,
          itemBuilder: (context, index) {
            final request = _requests[index];
            return Card(
              color: GlobalColor.MainCol,
              margin: EdgeInsets.all(8.0),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlobalColor.MainCol,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                          'https://calendar-files.woody1227.com/user_icon/${request.uicon}'),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${request.uname}　からのリクエスト',
                            style: TextStyle(
                              color: GlobalColor.SubCol,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            request.summary,
                            style: TextStyle(color: GlobalColor.SubCol),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "${DateFormat('yyyy-MM-dd HH:mm').format(request.startTime)} - ${DateFormat('yyyy-MM-dd HH:mm').format(request.endTime)}",
                            style: TextStyle(
                                fontSize: 12, color: GlobalColor.SubCol),
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _acceptRequest(request),
                                  child: Text("承認",
                                      style: TextStyle(
                                          color: GlobalColor.MainCol)),
                                  style: ButtonStyle(
                                    backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        GlobalColor.SubCol),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _denyRequest(request),
                                  child: Text("拒否",
                                      style: TextStyle(
                                          color: GlobalColor.MainCol)),
                                  style: ButtonStyle(
                                    backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        GlobalColor.SubCol),
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
              ),
            );
          },
        ),
      ),
    );
  }


}
