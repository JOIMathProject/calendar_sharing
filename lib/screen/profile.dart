import 'dart:convert';
import 'dart:io';
import 'package:calendar_sharing/screen/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import '../services/APIcalls.dart';
import '../setting/color.dart' as GlobalColor;
import '../services/auth.dart';
import 'package:image/image.dart' as img;

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final imagePicker = ImagePicker();
  bool isEditingUID = false;
  bool isEditingUsername = false;
  late TextEditingController uidController;
  late TextEditingController usernameController;

  @override
  void initState() {
    super.initState();
    // Initialize the controllers here
    final userData = Provider.of<UserData>(context, listen: false);
    uidController = TextEditingController(text: userData.uid);
    usernameController = TextEditingController(text: userData.uname);
  }
  Future<String?> getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Read the image file as bytes
      final imageBytes = await File(pickedFile.path).readAsBytes();

      // Decode the image bytes
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return null; // Could not decode the image
      }

      // Resize the image to 256x256
      final resizedImage = img.copyResize(image, width: 256, height: 256);

      // Correct the orientation if needed
      final rotatedImage = img.bakeOrientation(resizedImage);

      // Encode the corrected image back into bytes
      final correctedBytes = img.encodeJpg(rotatedImage);

      // Convert the bytes to a base64 string
      final base64String = base64Encode(correctedBytes);
      return base64String;
    }

    return null; // No image was picked
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
    final AuthService _auth = AuthService();
    return Scaffold(
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
                            String? image = await getImageFromGallery();
                            if (image != null) {
                              await UpdateUserImage()
                                  .updateUserImage(userData.uid, image);
                              UserInformation newUserData = await GetUser().getUser(userData.uid);
                              Provider.of<UserData>(context, listen: false).uicon = newUserData.uicon;
                              setState(() {});
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
                  restrictInput: true,
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
                    }
                    setState(() {
                      isEditingUID = false;
                    });
                  },
                ),
                buildProfileField(
                  context,
                  label: 'ユーザー名',
                  controller: usernameController,
                  isEditing: isEditingUsername,
                  restrictInput: false,
                  onEditToggle: () {
                    setState(() {
                      isEditingUsername = !isEditingUsername;
                    });
                  },
                  onSave: () async {
                    if (usernameController.text.isNotEmpty &&
                        usernameController.text != userData.uname) {
                      await UpdateUserName().updateUserName(
                          userData.uid, usernameController.text);
                      Provider.of<UserData>(context, listen: false).uname =
                          usernameController.text;
                    }
                    setState(() {
                      isEditingUsername = false;
                    });
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Wrapper()),
                );
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
  Widget buildProfileField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required bool isEditing,
        required bool restrictInput, // New parameter to control input restriction
        required VoidCallback onEditToggle,
        required VoidCallback onSave,
      }) {
    // Add listener to enforce 15-character limit
    controller.addListener(() {
      final text = controller.text;
      if (text.length > 15) {
        // Trim the text to 15 characters and update the controller
        controller.text = text.substring(0, 15);
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isEditing
              ? Expanded(
            child: TextField(
              maxLength: 15,
              controller: controller,
              style: TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: label,
              ),
              inputFormatters: restrictInput
                  ? [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              ]
                  : [], // No restriction if restrictInput is false
            ),
          )
              : Text(
              label == 'ユーザーID'
                  ? '$label: @${controller.text}'
                  : '$label: ${controller.text}',
              style: TextStyle(fontSize: 18)),
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: isEditing ? onSave : onEditToggle,
          ),
        ],
      ),
    );
  }
}
