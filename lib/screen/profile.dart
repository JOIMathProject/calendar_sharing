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
  void initState() {
    super.initState();
    GoogleSignIn? gUser = Provider.of<UserData>(context, listen: false).googleUser;
    if (gUser?.currentUser != null) {
      print('UID: ${gUser?.currentUser!.id}'); // Debugging
      _userDataFuture = GetUser().getUser(gUser?.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<UserInformation>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('UID: ${snapshot.data!.uid}', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 10),
                  Text('Username: ${snapshot.data!.uname}', style: TextStyle(fontSize: 20)),
                ],
              );
            } else {
              return Text('No data');
            }
          },
        ),
      ),
    );
  }
}