import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Future<UserInformation>? _userDataFuture;
  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('google_uid: ${userData.google_uid}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('UID: ${userData.uid}', style: TextStyle(fontSize: 20)),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Edit uid'),
                          // Add your form here
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('username: ${userData.uname}', style: TextStyle(fontSize: 20)),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Edit user name'),
                          // Add your form here
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            Image.network("https://calendar-files.woody1227.com/user_icon/${userData.uicon}"),
            SizedBox(height: 10),
            Text('Email: ${userData.mailAddress}', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}