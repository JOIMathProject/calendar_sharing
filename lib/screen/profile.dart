import 'dart:convert';
import 'dart:io';

import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/bigquerydatatransfer/v1.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final imagePicker = ImagePicker();

  Future<XFile?> getImageFromGallery() async {
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    XFile? _selectedImage;
    if (pickedFile != null) {
      _selectedImage = XFile(pickedFile.path);
    }
    return _selectedImage;
  }

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
                  onPressed: () async {
                    final newUid = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        String uidValue = '';
                        return AlertDialog(
                          title: Text('Edit UID'),
                          content: TextField(
                            decoration: InputDecoration(hintText: "Enter new UID"),
                            onChanged: (value) {
                              uidValue = value;
                            },
                          ),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(null);
                              },
                            ),
                            TextButton(
                              child: Text('Save'),
                              onPressed: () {
                                Navigator.of(context).pop(uidValue);
                              },
                            ),
                          ],
                        );
                      },
                    );
                    if (newUid != null && newUid.isNotEmpty) {
                      await UpdateUserID().updateUserID(userData.uid,newUid);
                      Provider.of<UserData>(context, listen: false).uid = newUid;
                    }
                  },
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Username: ${userData.uname}', style: TextStyle(fontSize: 20)),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    final newUsername = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        String unameValue = '';
                        return AlertDialog(
                          title: Text('Edit Username'),
                          content: TextField(
                            decoration: InputDecoration(hintText: "Enter new username"),
                            onChanged: (value) {
                              unameValue = value;
                            },
                          ),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(null);
                              },
                            ),
                            TextButton(
                              child: Text('Save'),
                              onPressed: () {
                                Navigator.of(context).pop(unameValue);
                              },
                            ),
                          ],
                        );
                      },
                    );
                    if (newUsername != null && newUsername.isNotEmpty) {
                      await UpdateUserName().updateUserName(userData.uid,newUsername);
                    }
                  },
                ),
              ],
            ),

            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.network(
                  "https://calendar-files.woody1227.com/user_icon/${userData.uicon}",
                  width: 100,
                  height: 100,
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    XFile? image = await getImageFromGallery();
                    if (image != null) {
                      List<int> imageBytes = await File(image.path).readAsBytesSync();
                      String base64Image = base64Encode(imageBytes);
                      await UpdateUserImage().updateUserImage(userData.uid, base64Image);
                    }
                  },
                ),
              ],
            ),

            SizedBox(height: 10),
            Text('Email: ${userData.mailAddress}', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
