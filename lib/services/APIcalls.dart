import 'package:http/http.dart' as http;
import 'dart:convert';

class UserInformation {
  final String uid;
  final String uname;
  final String refreshToken;
  final String mailAddress;

  UserInformation({required this.uid, required this.uname, required this.refreshToken, required this.mailAddress});

  factory UserInformation.fromJson(Map<String, dynamic> json) {
    return UserInformation(
      uid: json['uid'],
      uname: json['uname'],
      refreshToken: json['refresh_token'],
      mailAddress: json['mail_address'],
    );
  }
}

class CreateUser{
  Future<void> createUser(UserInformation) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid": UserInformation.uid,
        "uname": UserInformation.uname,
        "refresh_token":UserInformation.refreshToken,
        "mail_address":UserInformation.mailAddress
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create user: ${response.statusCode}';
    }
  }
}
class ChangeUserProfile{
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

class GetUser{
  Future<UserInformation> getUser(String? uid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user/$uid');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get user: ${response.statusCode}';
    }

    return UserInformation.fromJson(jsonDecode(response.body));
  }
}

class GetFriends{
  Future<List<String>> getFriends(String? uid) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/friends/$uid');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to get friends: ${response.statusCode}';
    }

    //responseの中のdataの中のuidだけをListにして返す
    List<String> friends = [];
    for (var friend in jsonDecode(response.body)['data']) {
      friends.add(friend['uid']);
    }
    return friends;
  }
}