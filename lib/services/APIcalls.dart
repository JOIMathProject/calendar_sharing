import 'dart:ui';

import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:syncfusion_flutter_calendar/calendar.dart';

class UserInformation {
  final String google_uid;
  final String uid;
  final String uname;
  final String uicon;
  final String refreshToken;
  final String mailAddress;

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
  GroupInformation(
      {required this.id,
      required this.gid,
      required this.gname,
      required this.gicon,
      required this.is_friends});
}
class MyContentsInformation {
  final String cid;
  final String cname;
  MyContentsInformation({
    required this.cid,
    required this.cname,
  });
}
class CalendarInformation{
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
  FriendRequestInformation({
    required this.uid,
    required this.uname,
    required this.uicon
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
      throw 'Failed to create user: ${response.statusCode}';
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
      throw 'Failed to create user: ${response.statusCode}';
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

    //responseの中のdataの中のuidだけをListにして返す
    List<FriendInformation> friends = [];
    for (var friend in jsonDecode(response.body)['data']) {
      if (friend['uicon'] == null) {
        friend['uicon'] =
            'https://calendar-api.woody1227.com/user_icon/default.png';
      }
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

class AddDeviceID {
  Future<void> addDeviceID(String? uid, String? deviceID) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid/deviceids');

    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "device_id": deviceID,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to add deviceID: ${response.statusCode}';
    }
  }
}

class AddFriendRequest {
  Future<void> addFriend(String uid, String friend_uid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/friends_requests/');
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
class GetGroupInfo{
  Future<List<GroupInformation>> getGroupInfo(String? uid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid/groups');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get group: ${response.statusCode}';
    }

    //responseの中のdataの中のuidだけをListにして返す
    List<GroupInformation> groups = [];
    for (var group in jsonDecode(response.body)['data']) {
      groups.add(GroupInformation(
        id: group['id'] ?? 0,
        gid: group['gid'] ?? 'default',
        gname: group['gname'] ?? 'default',
        gicon: group['gicon'] ?? 'default_icon.png',
        is_friends: group['is_friends'] ?? '0',
      ));
    }
    //print everything
    print("ghe");
    return groups;
  }
}
class UpdateUserID{
  Future<void> updateUserID(String? OldUid,String?NewUid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/${OldUid}');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid": NewUid,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create user: ${response.statusCode}';
    }
  }
}
class UpdateUserName{
  Future<void> updateUserName(String?uid, String? uname) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/${uid}');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uname": uname,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create user: ${response.statusCode}';
    }
  }
}
class UpdateUserImage{
  Future<void> updateUserImage(String?uid, String? uicon) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/${uid}');
    final response = await http.put(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uicon": uicon,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create user: ${response.statusCode}';
    }
  }
}
class GetGroupCalendar{
  Future<List<TimeRegion>> getGroupCalendar(String? gid,String? from, String? to) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/groups/$gid/content/events/$from/$to');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<TimeRegion> events = [];
    for (var group in jsonDecode(response.body)['data']) {
      int count = group['count'];
      // Ensure count is capped between 0 and 5
      count = count.clamp(0, 5);

      // Calculate the blue intensity
      int blueIntensity = (255 - (count * 51)); // 51 = 255 / 5

      // Create the color based on blueIntensity
      Color color = Color.fromARGB(255, 0, 0, blueIntensity);

      events.add(TimeRegion(
        startTime: DateTime.parse(group['start_dateTime']),
        endTime: DateTime.parse(group['end_dateTime']),
        color: color,
      ));
    }

    return events;
  }
}
class GetMyContents{
  Future<List<MyContentsInformation>> getMyContents(String? uid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid/contents');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<MyContentsInformation> contents = [];
    for (var group in jsonDecode(response.body)['data']) {
      contents.add(MyContentsInformation(
        cid: group['cid'],
        cname: group['cname'],
      ));
    }

    return contents;
  }
}
class GetMyCalendars{
  Future<List<CalendarInformation>> getMyCalendars(String? uid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid/calendars');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<CalendarInformation> contents = [];
    for (var group in jsonDecode(response.body)['data']) {
      contents.add(CalendarInformation(
        calendar_id: group['calendar_id']?? 'default',
        summary: group['summary']?? 'default',
        discription: group['discription']?? 'default',
      ));
    }

    return contents;
  }

}

class GetReceiveFriendRequest{
  Future<List<FriendRequestInformation>> getReceiveFriendRequest(String? uid) async {
    final url = Uri.parse(
        'https://calendar-api.woody1227.com/friends_requests/$uid/receive');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get group: ${response.statusCode}';
    }
    List<FriendRequestInformation> requests = [];
    for (var group in jsonDecode(response.body)['data']) {
      requests.add(FriendRequestInformation(
        uid: group['uid'],
        uname: group['uname'],
        uicon: group['uicon'],
      ));
    }

    return requests;
  }
}
class CreateEmptyContents{
  Future<String> createEmptyContents(String? uid, String? cname) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid/contents');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "cname": cname,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create user: ${response.statusCode}';
    }
    return response.body[0];
  }
}
class AddCalendarToContents{
  Future<void> addCalendarToContents(String? uid, String? cid, String? calendar_id) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid/contents/$cid/calendars');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "gid": calendar_id,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create user: ${response.statusCode}';
    }
  }
}