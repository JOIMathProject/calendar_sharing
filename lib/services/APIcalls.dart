import 'package:http/http.dart' as http;
import 'dart:convert';

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

    if (response.statusCode != 200) {
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
  Future<void> addDeviceID(String google_uid, String deviceID) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/device');

    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "google_uid": google_uid,
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
    final url = Uri.parse('https://calendar-api.woody1227.com/friends/$uid');

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
