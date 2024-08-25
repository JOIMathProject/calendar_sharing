import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import '../services/APIcalls.dart';
import '../setting/color.dart' as GlobalColor;

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final imagePicker = ImagePicker();

  Future<XFile?> getImageFromGallery() async {
    return await imagePicker.pickImage(source: ImageSource.gallery);
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sando',
          style: TextStyle(color: GlobalColor.MainCol,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pacifico'),
        ),
        backgroundColor: GlobalColor.SubCol,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                        "https://calendar-files.woody1227.com/user_icon/${userData.uicon}"),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        XFile? image = await getImageFromGallery();
                        if (image != null) {
                          List<int> imageBytes =
                          await File(image.path).readAsBytesSync();
                          String base64Image = base64Encode(imageBytes);
                          await UpdateUserImage().updateUserImage(
                              userData.uid, base64Image);
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 18,
                        child: Icon(Icons.edit, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            buildProfileField(
              context,
              label: 'UID',
              value: userData.uid!,
              onEdit: () async {
                final newUid = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    String uidValue = '';
                    return buildEditDialog(
                      context,
                      title: 'UIDを編集',
                      hintText: '新規UID',
                      onChanged: (value) => uidValue = value,
                      onSave: () => Navigator.of(context).pop(uidValue),
                    );
                  },
                );
                if (newUid != null && newUid.isNotEmpty) {
                  await UpdateUserID().updateUserID(userData.uid, newUid);
                  Provider.of<UserData>(context, listen: false).uid = newUid;
                }
              },
            ),
            buildProfileField(
              context,
              label: 'ユーザーネーム',
              value: userData.uname!,
              onEdit: () async {
                final newUsername = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    String unameValue = '';
                    return buildEditDialog(
                      context,
                      title: 'ユーザーネームを編集',
                      hintText: '新規ユーザーネーム',
                      onChanged: (value) => unameValue = value,
                      onSave: () => Navigator.of(context).pop(unameValue),
                    );
                  },
                );
                if (newUsername != null && newUsername.isNotEmpty) {
                  await UpdateUserName()
                      .updateUserName(userData.uid, newUsername);
                }
              },
            ),
            SizedBox(height: 20),
            Text('メールアドレス: ${userData.mailAddress}',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget buildProfileField(BuildContext context,
      {required String label,
        required String value,
        required VoidCallback onEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label: $value', style: TextStyle(fontSize: 18)),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  AlertDialog buildEditDialog(BuildContext context,
      {required String title,
        required String hintText,
        required ValueChanged<String> onChanged,
        required VoidCallback onSave}) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        decoration: InputDecoration(hintText: hintText),
        onChanged: onChanged,
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
          onPressed: onSave,
        ),
      ],
    );
  }
}
