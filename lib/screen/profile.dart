import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import '../services/APIcalls.dart';
import '../setting/color.dart' as GlobalColor;
import '../services/auth.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final imagePicker = ImagePicker();
  bool isEditingUID = false;
  bool isEditingUsername = false;
  TextEditingController uidController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  Future<XFile?> getImageFromGallery() async {
    return await imagePicker.pickImage(source: ImageSource.gallery);
  }

  @override
  void dispose() {
    uidController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);

    uidController.text = userData.uid!;
    usernameController.text = userData.uname!;

    final AuthService _auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sando',
          style: TextStyle(
            color: GlobalColor.MainCol,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',
          ),
        ),
        backgroundColor: GlobalColor.SubCol,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
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
                              print('updating$base64Image');
                              await UpdateUserImage()
                                  .updateUserImage(userData.uid, base64Image);
                              setState(() {}); // Refresh the widget to update UI
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
                  label: 'ユーザーID',
                  controller: uidController,
                  isEditing: isEditingUID,
                  onEditToggle: () {
                    setState(() {
                      isEditingUID = !isEditingUID;
                    });
                  },
                  onSave: () async {
                    if (uidController.text.isNotEmpty &&
                        uidController.text != userData.uid) {
                      await UpdateUserID()
                          .updateUserID(userData.uid, uidController.text);
                      Provider.of<UserData>(context, listen: false).uid =
                          uidController.text;
                      setState(() {
                        isEditingUID = false;
                      });
                    }
                  },
                ),
                buildProfileField(
                  context,
                  label: 'ユーザー名',
                  controller: usernameController,
                  isEditing: isEditingUsername,
                  onEditToggle: () {
                    setState(() {
                      isEditingUsername = !isEditingUsername;
                    });
                  },
                  onSave: () async {
                    if (usernameController.text.isNotEmpty &&
                        usernameController.text != userData.uname) {
                      await UpdateUserName()
                          .updateUserName(userData.uid, usernameController.text);
                      Provider.of<UserData>(context, listen: false).uname =
                          usernameController.text;
                      setState(() {
                        isEditingUsername = false;
                      });
                    }
                  },
                ),
                SizedBox(height: 20),
                Text('メールアドレス: ${userData.mailAddress}',
                    style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                _auth.signOut(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: GlobalColor.MainCol,
              ),
              child: Text(
                'ログアウト',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileField(BuildContext context,
      {required String label,
        required TextEditingController controller,
        required bool isEditing,
        required VoidCallback onEditToggle,
        required VoidCallback onSave}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isEditing
              ? Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: label,
              ),
            ),
          )
              : Text('$label: ${controller.text}', style: TextStyle(fontSize: 18)),
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: isEditing ? onSave : onEditToggle,
          ),
        ],
      ),
    );
  }
}
