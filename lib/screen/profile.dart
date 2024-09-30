import 'dart:convert';
import 'dart:io';
import 'package:calendar_sharing/screen/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/UserData.dart';
import '../services/APIcalls.dart';
import 'ReadQR.dart';
import '../setting/color.dart' as GlobalColor;
import '../services/auth.dart';
import 'package:image/image.dart' as img;

import 'mainScreen.dart';

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

      // Correct the orientation if needed
      final rotatedImage = img.bakeOrientation(image);

      int width = rotatedImage.width;
      int height = rotatedImage.height;
      int squareSide = width < height ? width : height;

      int targetSize = squareSide < 256 ? squareSide : 256;

      int offsetX = (width - squareSide) ~/ 2;
      int offsetY = (height - squareSide) ~/ 2;
      final croppedImage = img.copyCrop(
        rotatedImage,
        x: offsetX,
        y: offsetY,
        width: squareSide,
        height: squareSide,
        radius: 0,
        antialias: true,
      );

      final resizedImage = img.copyResize(
        croppedImage,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.average,
      );

      final correctedBytes = img.encodeJpg(resizedImage);

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

    return WillPopScope(
      onWillPop: () async {
        // Return false to disable the back button
        mainScreenKey.currentState?.updateTab(0);
        return false;
      },
      child: Scaffold(
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
                                UserInformation newUserData =
                                    await GetUser().getUser(userData.uid);
                                Provider.of<UserData>(context, listen: false)
                                    .uicon = newUserData.uicon;
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
                  Spacer(
                    flex: 2,
                  ),
                  Center(
                    child: ElevatedButton(
                      // Removed 'const' from Padding to allow dynamic colors
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize
                              .min, // Ensures minimal vertical space
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 50,
                              color: Colors
                                  .black, // Ensure SubCol is correctly defined
                            ),
                            SizedBox(
                                height:
                                    8), // Adds some spacing between Icon and Text
                            Text('自分のQRを表示',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black)),
                          ],
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return MyQRModal(uid: userData.uid);
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColor
                            .SubCol, // Optional: Set button background color
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              color: Colors.grey,
                              width: 2), // Optional: Border width
                          borderRadius: BorderRadius.circular(
                              12), // Optional: Rounded corners
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5), // Optional: Adjust padding
                      ),
                    ),
                  ),
                  Spacer(
                    flex: 3,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom:
                  50, // You can adjust this value to position the button vertically
              left: 0,
              right: 0, // This makes the Positioned span the full width
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centers the button horizontally
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _auth.signOut(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Wrapper()),
                      );
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      'ログアウト',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 100, vertical: 12),
                      backgroundColor: GlobalColor.logOutCol,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 5.0),
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
                      labelText: label,
                      hintText: label,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey, // 編集時の下線の色
                        ),
                      ),
                    ),
                    inputFormatters: restrictInput
                        ? [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9_]')),
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
