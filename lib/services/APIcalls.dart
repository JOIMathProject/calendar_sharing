import 'dart:ui';
import 'package:googleapis/admob/v1.dart';
import 'package:googleapis/calendar/v3.dart' as googleAPI;
import 'package:googleapis/customsearch/v1.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';

class UserInformation {
  String google_uid;
  String uid;
  String uname;
  String uicon;
  String refreshToken;
  String mailAddress;
  String APIKey = '53353d2d-22c8-b857-0870-f677689d8642';
  UserInformation(
      {required this.google_uid,
      required this.uid,
      required this.uname,
      required this.uicon,
      required this.refreshToken,
      required this.mailAddress});

  factory UserInformation.fromJson(Map<String, dynamic> json) {
    return UserInformation(
      google_uid: json['google_uid'],
      uid: json['uid'],
      uname: json['uname'],
      uicon: json['uicon'],
      refreshToken: json['refresh_token'],
      mailAddress: json['mail_address'],
    );
  }
}

class FriendInformation {
  final String uid;
  final String uname;
  final String uicon;
  final String gid;
  FriendInformation(
      {required this.uid,
      required this.uname,
      required this.uicon,
      required this.gid});
}

class GroupInformation {
  final int id;
  final String gid;
  final String gname;
  final String gicon;
  final String is_friends;
  final int unread_messages;
  final String latest_message;
  final DateTime latest_message_time;
  final String is_opened;
  GroupInformation(
      {required this.id,
      required this.gid,
      required this.gname,
      required this.gicon,
      required this.is_friends,
      required this.unread_messages,
      required this.latest_message,
      required this.latest_message_time,
      required this.is_opened});
}

class MyContentsInformation {
  final String cid;
  final String cname;
  MyContentsInformation({
    required this.cid,
    required this.cname,
  });
}

class ContentsInformation {
  final String cid;
  final String cname;
  final String uid;
  ContentsInformation({
    required this.cid,
    required this.cname,
    required this.uid,
  });
}

class CalendarInformation {
  final String calendar_id;
  final String summary;
  final String discription;
  CalendarInformation({
    required this.calendar_id,
    required this.summary,
    required this.discription,
  });
}

class FriendRequestInformation {
  final String uid;
  final String uname;
  final String uicon;
  final bool isReceived;
  FriendRequestInformation({
    required this.uid,
    required this.uname,
    required this.uicon,
    required this.isReceived,
  });
}

class ChatMessage {
  final String mid;
  final String content;
  final String uid;
  final String uname;
  final String uicon;
  final DateTime sendTime;
  ChatMessage({
    required this.mid,
    required this.content,
    required this.uid,
    required this.uname,
    required this.uicon,
    required this.sendTime,
  });
}

class GroupDetail {
  String gid;
  String gname;
  String gicon;
  String is_friends;
  GroupDetail(
      {required this.gid,
      required this.gname,
      required this.gicon,
      required this.is_friends});
}

class SearchResultEvent {
  DateTime startTime;
  DateTime endTime;
  int count;
  List<UserInformation> members;
  int weather;
  String reliability;
  SearchResultEvent({
    required this.startTime,
    required this.endTime,
    required this.count,
    required this.members,
    required this.weather,
    required this.reliability,
  });
}

class eventRequest{
  String event_request_id;
  String uid;
  String uname;
  String uicon;
  String summary;
  DateTime startTime;
  DateTime endTime;
  eventRequest({
    required this.event_request_id,
    required this.uid,
    required this.uname,
    required this.uicon,
    required this.summary,
    required this.startTime,
    required this.endTime,
  });
}
class CreateUser {
  Future<void> createUser(UserInformation) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "google_uid": UserInformation.google_uid,
        "uid": UserInformation.uid,
        "uname": UserInformation.uname,
        "uicon": UserInformation.uicon,
        "refresh_token": UserInformation.refreshToken,
        "mail_address": UserInformation.mailAddress
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create user: ${response.statusCode} ${response.body}';
    }
  }
}

class ChangeUserProfile {
  Future<void> changeUserProfile(String uid, String uname) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uname": uname,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to change user: ${response.statusCode}';
    }
  }
}

class GetUser {
  Future<UserInformation> getUser(String? uid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get user: ${response.statusCode}';
    }

    return UserInformation.fromJson(jsonDecode(response.body));
  }
}

class GetUserGoogleUid {
  Future<UserInformation> getUserGoogleUid(String? google_uid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/user/$google_uid/google_uid');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get user: ${response.statusCode}';
    }

    return UserInformation.fromJson(jsonDecode(response.body));
  }
}

class GetFriends {
  Future<List<FriendInformation>> getFriends(String? uid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/friends/$uid');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get friends: ${response.statusCode}';
    }
    List<FriendInformation> friends = [];
    if (jsonDecode(response.body)['data'] == null) {
      return friends;
    }
    for (var friend in jsonDecode(response.body)['data']) {
      friends.add(FriendInformation(
        uid: friend['uid'],
        uname: friend['uname'],
        uicon: friend['uicon'],
        gid: friend['gid'],
      ));
    }
    return friends;
  }
}

class DeleteFriend {
  Future<void> deleteFriend(String? uid, String? friend_uid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/friends/$uid/$friend_uid');
    final response = await http.delete(url);
    if (response.statusCode != 204) {
      throw 'Failed to delete friend: ${response.statusCode}';
    }
  }
}

class CheckFriend {
  Future<String> checkFriend(String? uid, String? friend_uid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/friends/$uid/$friend_uid');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get friends: ${response.statusCode}';
    }
    final responseBody = jsonDecode(response.body);

    return responseBody['gid'];
  }
}

class AddDeviceID {//TEMPORARY UNAVAILABLE
  Future<void> addDeviceID(String? uid, String? deviceID) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/user/$uid/deviceids');

    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "device_id": deviceID,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 500) {
      throw 'Failed to add deviceID: ${response.statusCode}';
    }
  }
}

class AddFriendRequest {
  Future<void> addFriend(String uid, String friend_uid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/friends_requests/');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid1": uid,
        "uid2": friend_uid,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to add friend: ${response.statusCode}';
    }
  }
}

class GetGroupDetail {
  Future<GroupDetail> getGroupDetail(String? gid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/groups/$gid');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get group: ${response.statusCode}';
    }

    final responseBody = jsonDecode(response.body);

    return GroupDetail(
      gid: responseBody['gid'] ?? '',
      gname: responseBody['gname'] ?? '',
      gicon: responseBody['gicon'] ?? '',
      is_friends: responseBody['is_friends'] ?? '0',
    );
  }
}

class GetGroupInfo {
  Future<List<GroupInformation>> getGroupInfo(String? uid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/user/$uid/groups/detail');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get group: ${response.statusCode}';
    }

    //responseの中のdataの中のuidだけをListにして返す
    List<GroupInformation> groups = [];
    if(jsonDecode(response.body)['data'] == null){
      return groups;
    }
    for (var group in jsonDecode(response.body)['data']) {
      DateTime latestMessageTime;
      if (group['latest_message']['sent_time'] != null) {
        latestMessageTime =
            DateTime.parse(group['latest_message']['sent_time']);
      } else {
        latestMessageTime = DateTime.parse(group['created_time']);
      }
      groups.add(GroupInformation(
        id: group['id'] ?? 0,
        gid: group['gid'] ?? 'default',
        gname: group['gname'] ?? 'default',
        gicon: group['gicon'] ?? '',
        is_friends: group['is_friends'] ?? '0',
        unread_messages: int.parse(group['unread_count']) ?? 0,
        latest_message: group['latest_message']['content'] ?? '',
        latest_message_time: latestMessageTime,
        is_opened: group['is_opened'],
      ));
    }
    return groups;
  }
}

class CreateEmptyGroup {
  Future<String> createEmptyGroup(String gname, String gicon) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/groups');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "gname": gname,
        "gicon": gicon,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create group: ${response.statusCode}';
    }
    final responseBody = jsonDecode(response.body);

    if (responseBody.containsKey('gid')) {
      return responseBody['gid'];
    } else {
      throw 'cid not found in the response';
    }
  }
}

class AddUserToGroup {
  Future<void> addUserToGroup(String? gid, String? addUid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/groups/$gid/members');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({"uid": addUid}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to add contents: ${response.statusCode}';
    }
  }
}

class DeleteUserFromGroup {
  Future<void> deleteUserFromGroup(String? gid, String? deleteUid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/members/$deleteUid');
    final response = await http.delete(url);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw 'Failed to delete contents: ${response.statusCode}';
    }
  }
}

class GetUserInGroup {
  Future<List<UserInformation>> getUserInGroup(String? gid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/groups/$gid/members');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<UserInformation> users = [];
    for (var group in jsonDecode(response.body)['data']) {
      users.add(UserInformation(
        google_uid: '',
        uid: group['uid'] ?? 'default',
        uname: group['uname'] ?? 'default',
        uicon: group['uicon'] ?? 'default',
        refreshToken: group['refresh_token'] ?? 'default',
        mailAddress: group['mail_address'] ?? 'default',
      ));
    }

    return users;
  }
}

class UpdateGroupName {
  Future<void> updateGroupName(String? gid, String? gname) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/groups/$gid');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "gname": gname,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create group: ${response.statusCode}';
    }
  }
}

class UpdateGroupIcon {
  Future<void> updateGroupIcon(String? gid, String? gicon) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/groups/$gid');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "gicon": gicon,
      }),
    );
    print('$gid  $gicon success!');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create group: ${response.statusCode}';
    }
  }
}

class GetContentInGroup {
  Future<List<ContentsInformation>?> getContentInGroup(String? gid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/groups/$gid/content');
    final response = await http.get(url);
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<ContentsInformation> contents = [];
    for (var group in jsonDecode(response.body)['data']) {
      contents.add(ContentsInformation(
        cid: group['cid'],
        cname: group['cname'],
        uid: group['uid'],
      ));
    }
    return contents;
  }
}

class AddContentsToGroup {
  Future<void> addContentsToGroup(String? gid, String? cid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/groups/$gid/contents');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({"cid": cid}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to add contents: ${response.statusCode}';
    }
  }
}

class RemoveContentsFromGroup {
  Future<void> removeContentsFromGroup(String? gid, String? cid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/contents/$cid');
    final response = await http.delete(url);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw 'Failed to delete contents: ${response.statusCode}';
    }
  }
}

class UpdateUserID {
  Future<void> updateUserID(String? OldUid, String? NewUid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/${OldUid}');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid": NewUid,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to update user id: ${response.statusCode}';
    }
  }
}

class UpdateUserName {
  Future<void> updateUserName(String? uid, String? uname) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/${uid}');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uname": uname,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to update username: ${response.statusCode}';
    }
  }
}

class UpdateUserImage {
  Future<void> updateUserImage(String? uid, String? uicon) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/${uid}');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uicon": uicon,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to update userImage: ${response.statusCode}';
    }
  }
}

class GetGroupCalendar {
  Future<List<Appointment>> getGroupCalendar(
      String? gid, String? from, String? to) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/content/events/$from/$to');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get group: ${response.statusCode}';
    }

    List<Appointment> events = [];
    if(jsonDecode(response.body)['data'] == null){
      return events;
    }
    for (var group in jsonDecode(response.body)['data']) {
      int count = group['count'];
      // Ensure count is capped between 0 and 10
      count = count.clamp(0, 10);

      // Define the base orange color (at intensity 10)
      final Color intenseOrange =
          Color(0xFFFF8200); // You can adjust this as needed

      // Calculate the amount to reduce the intensity based on the input
      double factor = 1 - ((count - 1) / 2);
      Color minOrange = Color(0xFFFFD8AF);
      // Blend the orange with white to lighten it
      Color color = Color.lerp(intenseOrange, minOrange, factor)!;

      // Parse member information
      List<FriendInformation> members = [];
      for (var member in group['members']) {
        members.add(FriendInformation(
          uid: member['uid'],
          gid: '',
          uname: member['uname'],
          uicon: member['uicon'],
        ));
      }

      // Create the subject with the member names
      String subject = members.map((m) => m.uname).join('\n');

      events.add(Appointment(
        startTime: DateTime.parse(group['start_dateTime']),
        endTime: DateTime.parse(group['end_dateTime']),
        color: color,
        subject: subject,
        // Assuming you have a way to attach members to the Appointment
        notes: 'Participants: ${subject}',
      ));
    }

    return events;
  }
}

class GetMyContents {
  Future<List<MyContentsInformation>> getMyContents(String? uid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/user/$uid/contents');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<MyContentsInformation> contents = [];
    if (jsonDecode(response.body)['data'] == null) {
      return contents;
    }
    for (var group in jsonDecode(response.body)['data']) {
      contents.add(MyContentsInformation(
        cid: group['cid'],
        cname: group['cname'],
      ));
    }

    return contents;
  }
}

class GetMyCalendars {
  Future<List<CalendarInformation>> getMyCalendars(String? uid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/user/$uid/calendars');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<CalendarInformation> contents = [];
    if(jsonDecode(response.body)['data'] == null){
      return contents;
    }
    for (var group in jsonDecode(response.body)['data']) {
      contents.add(CalendarInformation(
        calendar_id: group['calendar_id'] ?? 'default',
        summary: group['summary'] ?? 'default',
        discription: group['discription'] ?? 'default',
      ));
    }

    return contents;
  }
}

class GetReceiveFriendRequest {
  Future<List<FriendRequestInformation>> getReceiveFriendRequest(
      String? uid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/friends_requests/$uid/receive');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get friend request: ${response.statusCode}';
    }
    List<FriendRequestInformation> requests = [];
    if (jsonDecode(response.body)['data'] == null) {
      return requests;
    }
    for (var group in jsonDecode(response.body)['data']) {
      requests.add(FriendRequestInformation(
        uid: group['uid'],
        uname: group['uname'],
        uicon: group['uicon'],
        isReceived: true,
      ));
    }

    return requests;
  }
}

class GetSentFriendRequest {
  Future<List<FriendRequestInformation>> getSentFriendRequest(
      String? uid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/friends_requests/$uid/send');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get friend request: ${response.statusCode}';
    }
    List<FriendRequestInformation> requests = [];
    if (jsonDecode(response.body)['data'] == null) {
      return requests;
    }
    for (var group in jsonDecode(response.body)['data']) {
      requests.add(FriendRequestInformation(
        uid: group['uid'],
        uname: group['uname'],
        uicon: group['uicon'],
        isReceived: false,
      ));
    }

    return requests;
  }
}

class CreateEmptyContents {
  Future<String> createEmptyContents(String? uid, String? cname) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/user/$uid/contents');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({"cname": cname}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create content: ${response.statusCode}';
    }
    final responseBody = jsonDecode(response.body);

    // Extract the 'cid' field
    if (responseBody.containsKey('cid')) {
      return responseBody['cid'];
    } else {
      throw 'cid not found in the response';
    }
  }
}

class AddCalendarToContents {
  Future<void> addCalendarToContents(
      String? uid, String? cid, String? calendar_id) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/user/$uid/contents/$cid/calendars');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({"calendar_id": calendar_id}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to add contents: ${response.statusCode}';
    }
  }
}
class DeleteCalendarFromContents {
  Future<void> deleteCalendarFromContents(
      String? uid, String? cid, String? calendar_id) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/user/$uid/contents/$cid/calendars/$calendar_id');
    final response = await http.delete(url);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw 'Failed to delete contents: ${response.statusCode}';
    }
  }
}
class GetMyContentsSchedule {
  Future<List<Appointment>> getMyContentsSchedule(
      String? uid, String? cid, String? from, String? to) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/user/$uid/contents/$cid/events/$from/$to');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get calendar: ${response.statusCode}';
    }
    List<Appointment> events = [];
    for (var group in jsonDecode(response.body)['data']) {
      events.add(Appointment(
          startTime: DateTime.parse(group['start_dateTime']),
          endTime: DateTime.parse(group['end_dateTime']),
          subject: group['summary']));
    }

    return events;
  }
}

class DeleteMyContents {
  Future<void> deleteMyContents(String? uid, String? cid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/user/$uid/contents/$cid');
    final response = await http.delete(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw 'Failed to delete contents: ${response.statusCode}';
    }
  }
}

class UpdateMyContents {
  Future<void> updateContents(String uid, String cid, String cname) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/user/$uid/contents/$cid');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "cname": cname,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to update contents: ${response.statusCode}';
    }
  }
}

class GetMyContentCalendars {
  Future<List<CalendarInformation>> getMyContentCalenders(String? uid,
      String? cid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/user/$uid/contents/$cid/calendars');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<CalendarInformation> contents = [];
    if (jsonDecode(response.body)['data'] == null) {
      return contents;
    }
    for (var group in jsonDecode(response.body)['data']) {
      contents.add(CalendarInformation(
        calendar_id: group['calendar_id'] ?? 'default',
        summary: group['summary'] ?? 'default',
        discription: group['discription'] ?? 'default',
      ));
    }
    return contents;
  }
}

class AcceptFriendRequest {
  Future<void> acceptFriendRequest(String? uid, String? friend_uid) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/friends_requests/');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid1": uid,
        "uid2": friend_uid,
      }),
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 404) {
      throw 'Failed to accept friend request: ${response.statusCode}';
    }
  }
}

class DeleteFriendRequest {
  Future<void> deleteFriendRequest(String? uid, String? friend_uid) async {
    //フレンド申請拒否
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/friends_requests/$friend_uid/$uid');
    final response = await http.delete(url);
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 404 &&
        response.statusCode != 204) {
      throw 'Failed to delete friend request: ${response.statusCode}';
    }
  }
}

class GetChatMessages {
  Future<List<ChatMessage>> getChatMessages(
      String? gid, String? mid, int limit, String? uid) async {
    if (mid == null || mid == '0') {
      mid = '';
    }
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/member/$uid/messages/before/$limit/$mid');
    final response = await http.get(url);
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 404) {
      throw 'Failed to get chat messages: ${response.statusCode}';
    }
    List<ChatMessage> messages = [];
    if (jsonDecode(response.body)['data'] == null) {
      return messages;
    }
    for (var group in jsonDecode(response.body)['data']) {
      final DateTime sendTime = DateTime.parse(group['sent_time']);
      messages.add(ChatMessage(
        mid: group['mid'],
        content: group['content'],
        uid: group['uid'],
        uname: group['uname'],
        uicon: group['uicon'],
        sendTime: sendTime,
      ));
    }

    return messages;
  }
}

class SendChatMessage {
  Future<String> sendChatMessage(
      String? gid, String? uid, String? content) async {
    final url =
        Uri.parse('https://calendar-api.woody1227.com/groups/$gid/messages');
    //print('sendChatMessage: $gid, $uid, $content');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid": uid,
        "content": content,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to send chat message: ${response.statusCode}';
    }
    final responseBody = jsonDecode(response.body);
    return responseBody['mid'];
  }
}

class GetChatNewMessage {
  Future<List<ChatMessage>> getChatNewMessage(
      String? gid, int limit, String? mid, String? uid) async {
    if (mid == '0') {
      mid = '';
    }
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/member/$uid/messages/after/100/$mid');
    final response = await http.get(url);
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 404) {
      throw 'Failed to get chat messages: ${response.statusCode}';
    }
    List<ChatMessage> messages = [];
    if (jsonDecode(response.body)['data'] == null) {
      return messages;
    }
    for (var group in jsonDecode(response.body)['data']) {
      final DateTime sendTime = DateTime.parse(group['sent_time']);
      messages.add(ChatMessage(
        mid: group['mid'],
        content: group['content'],
        uid: group['uid'],
        uname: group['uname'],
        uicon: group['uicon'],
        sendTime: sendTime,
      ));
    }

    return messages;
  }
}

class SearchContentSchedule {
  Future<List<SearchResultEvent>> searchContentSchedule(
      String? gid,
      String? from_date,
      String? to_date,
      String? from_hour,
      String? from_minute,
      String? to_hour,
      String? to_minute,
      String? limit_time,
      String? limit_count) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/content/events/$from_date/$to_date/$from_hour/$from_minute/$to_hour/$to_minute/$limit_time/$limit_count');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get calendar: ${response.statusCode}';
    }
    List<SearchResultEvent> events = [];
    for (var group in jsonDecode(response.body)['data']) {
      List<UserInformation> _members = [];
      for (var member in group['members']) {
        _members.add(UserInformation(
          google_uid: '',
          uid: member['uid'],
          uname: member['uname'],
          uicon: member['uicon'],
          refreshToken: '',
          mailAddress: '',
        ));
      }
      events.add(SearchResultEvent(
        startTime: DateTime.parse(group['start_dateTime']),
        endTime: DateTime.parse(group['end_dateTime']),
        count: group['count'],
        members: _members,
        weather: -1,
        reliability: '',
      ));
    }

    return events;
  }
}

class SearchContentScheduleWeather {
  Future<List<SearchResultEvent>> searchContentScheduleWeather(
      String? gid,
      String? from_date,
      String? to_date,
      String? from_hour,
      String? from_minute,
      String? to_hour,
      String? to_minute,
      String? limit_time,
      String? limit_count,
      String? area_code,
      String? sunny,
      String? cloudy,
      String? rainy,
      String? snowy) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/content/events/'
        '$from_date/$to_date/$from_hour/$from_minute/$to_hour/$to_minute/$limit_time/$limit_count/'
        '$area_code/$sunny/$cloudy/$rainy/$snowy');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get calendar: ${response.statusCode}';
    }
    List<SearchResultEvent> events = [];
    for (var group in jsonDecode(response.body)['data']) {
      List<UserInformation> _members = [];
      for (var member in group['members']) {
        _members.add(UserInformation(
          google_uid: '',
          uid: member['uid'],
          uname: member['uname'],
          uicon: member['uicon'],
          refreshToken: '',
          mailAddress: '',
        ));
      }
      events.add(SearchResultEvent(
        startTime: DateTime.parse(group['start_dateTime']),
        endTime: DateTime.parse(group['end_dateTime']),
        count: group['count'],
        members: _members,
        weather: group['weather'],
        reliability: group['reliabilities'] ?? '-',
      ));
    }

    return events;
  }
}

class GetEventRequest {
  Future<List<eventRequest>> getEventRequest(
      String? uid, String? gid) async {
    print('getEventRequest: $uid, $gid');
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/event_requests/$uid/receive');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get event request: ${response.statusCode}';
    }
    List<eventRequest> requests = [];
    if (jsonDecode(response.body)['data'] == null) {
      return requests;
    }
    for (var group in jsonDecode(response.body)['data']) {
      requests.add(eventRequest(
        event_request_id: group['event_request_id'],
        uid: group['uid'],
        uname: group['uname'],
        uicon: group['uicon'],
        summary: group['summary'],
        startTime: DateTime.parse(group['start_dateTime']),
        endTime: DateTime.parse(group['end_dateTime']),
      ));
    }
    return requests;
  }
}
class SendEventRequest{
  Future<void> sendEventRequest(String? uid,String? uid2, String? gid, String? summary, DateTime? startTime, DateTime? endTime) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/groups/$gid/event_requests');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid1": uid,
        "uid2": uid2,
        "summary": summary,
        "description": '',
        "start_dateTime": startTime.toString().substring(0,19),
        "end_dateTime": endTime.toString().substring(0,19),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to send event request: ${response.statusCode}';
    }
  }
}
class ReceiveEventRequest{
  Future<void> receiveEventRequest(String? uid,String? uid2,String? gid,String? event_request_id, String? calendar_id) async {
    print('receiveEventRequest: $uid, $uid2, $gid, $event_request_id, $calendar_id');
    final url = Uri.parse('https://calendar-api.woody1227.com/groups/$gid/event_requests');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid1": uid2,
        "uid2": uid,
        "event_request_id": event_request_id,
        "calendar_id": calendar_id,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to receive event request: ${response.statusCode}';
    }
  }
}
class RejectEventRequest{
  Future<void> rejectEventRequest(String? uid,String? uid2,String? gid,String? event_request_id) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/groups/$gid/event_requests/$uid2/$uid/$event_request_id');
    final response = await http.delete(url);
    if (response.statusCode != 200 && response.statusCode != 201&& response.statusCode != 204) {
      throw 'Failed to send event request: ${response.statusCode}';
    }
  }
}
class GetOpened {
  Future<String> getOpened(String? uid, String? gid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/user/$uid/group/$gid/opened');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get opened information: ${response.statusCode}';
    }

    final responseBody = jsonDecode(response.body);
    return responseBody['is_opened'];
  }
}
class SetOpened {
  Future<void> setOpened(String? uid, String? gid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/user/$uid/group/$gid/opened');
    final response = await http.put(url);

    if (response.statusCode != 200 && response.statusCode != 404 && response.statusCode != 201) {
      throw 'Failed to get opened information: ${response.statusCode}';
    }
    return;
  }
}
class GetGroupPrimaryCalendar{
  Future<String> getGroupPrimaryCalendar(String? gid,String? uid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/members/$uid/primary_calendar');
    final response = await http.get(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to get primary calendar: ${response.statusCode}';
    }

    final responseBody = jsonDecode(response.body);
    return responseBody['calendar_id'];
  }
}
class SetGroupPrimaryCalendar{
  Future<void> setGroupPrimaryCalendar(String? gid,String? uid,String? calendar_id) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/members/$uid/primary_calendar');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "calendar_id": calendar_id,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 404 && response.statusCode != 201) {
      throw 'Failed to set primary calendar: ${response.statusCode}';
    }
    return;
  }
}
class DeleteGroupPrimaryCalendar{
  Future<void> deleteGroupPrimaryCalendar(String? gid,String? uid,String? calendar_id) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/groups/$gid/members/$uid/primary_calendar/$calendar_id');
    final response = await http.delete(url);

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw 'Failed to delete primary calendar: ${response.statusCode}';
    }
    return;
  }
}
class AddEventToTheCalendar{
  Future<void> addEventToTheCalendar(String? uid,String? calendar_id,String? summary,String? description,DateTime? start_dateTime,DateTime? end_dateTime) async {
    print('addEventToTheCalendar: $uid, $calendar_id, $summary, $description, $start_dateTime, $end_dateTime');
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/user/$uid/calendars/$calendar_id/events');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'
      },
      body: jsonEncode({
        "summary": summary,
        "description": description,
        "start_dateTime": start_dateTime.toString().substring(0,19),
        "end_dateTime": end_dateTime.toString().substring(0,19),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to add event to the calendar: ${response.statusCode}';
    }
    return;
  }
}