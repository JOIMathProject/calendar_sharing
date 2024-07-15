import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateUser{
  Future<void> createUser(String uid, String uname) async {
    final url = Uri.parse('https://calendar-api.woody1227.com/user');
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "uid": uid,
        "uname": uname,
        "refresh_token":"Hellop"
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to create user: ${response.statusCode}';
    }
  }
}
