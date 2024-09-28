import 'dart:convert';

import 'package:calendar_sharing/screen/loadingScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../setting/color.dart' as GlobalColor;

class CreateUserScreen extends StatefulWidget {
  final GoogleSignInAccount result;
  final String refresh_token;
  const CreateUserScreen({required this.result, required this.refresh_token});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  bool isEditingUID = false;
  bool isEditingUsername = false;
  TextEditingController uidController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  bool loading = false;
  UserInformation userInformation = UserInformation(
    uid: "",
    uname: "",
    uicon: "",
    refreshToken: "",
    mailAddress: "",
    google_uid: "",
  );
  final imagePicker = ImagePicker();

  String? imageFile =
      '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wgARCADsAOwDASIAAhEBAxEB/8QAGgABAQEAAwEAAAAAAAAAAAAAAAUEAQIDBv/EABQBAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhADEAAAAftAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHbg4AAAAAAAAAAAA9PaqZNXYAeWKkPn1mQdQAAAAAAAAPbxsHvyAAADNpHz7VlAAAAAAAAO92PYAAAAAMkq3EAAAAAAAANFiFdAAAAAPKJWkgAAAAAAACzG9yyAAAAZzDlAAAAAAAAADXV+f9i0y6TkB54jXH44AAAAAAAAAAD02k7tZ9SP1tD59fzkhsxgAAAAAAAA7HFDR7gAAADz9BHz/AEEsxgAAAAAAWM1EAAAAAAAk5b0Q6AAAAAduu4o8gAAAAAAAw7uCA54AAAAFeRdO4AAAAAAAAI+fdhAAAAF+BfOQAAAAAAAAT59CeAAf/8QAJBAAAgEEAgIDAAMAAAAAAAAAAQIDABIwQAQRITMQIDEjMnD/2gAIAQEAAQUC/wAktNdHaRC9LAooAD5aNWp4CNeGK+gOh9pIw9MCp04kvYeMM0d66cC2pi5C2vooO2x8kdx6PH9uOX16PH9uOX16KHp8fJPUelC1yYuQ3b6UL2NhmexdSGW3BJIEDMWOqkhSlnU1+/LOq089E97I7r+WjfsojNS8ehGo+hANNChp4GGoPNRwYnQPUkRTRUFjFGEGSaK3QhjsGaeOw5eMmgwuDLa2NRcwHQ0OSvjHxV86LDsHwcXHHUelOOpcSeE0uV/bEPzS5eMfmly/t//EABQRAQAAAAAAAAAAAAAAAAAAAHD/2gAIAQMBAT8BYf/EABQRAQAAAAAAAAAAAAAAAAAAAHD/2gAIAQIBAT8BYf/EACgQAAAGAQQBAgcAAAAAAAAAAAABESEwQGECICIxElFxEDJBQnCBkf/aAAgBAQAGPwL8SdGOrTDk4Yvi5Di9dT+UNvyEOon0izUycfvSIpF9KRSaqRSaqRHJ73k9KeIs1U1dQZCnWYO2xzHAPZZR94fyssQ5GGItjjpAz1V1/wAicYooQzKunqhmdS6m8j/VBDCHIRBKPlIZ0kkKmcZUyvaYyp6d3//EACkQAQAABQMEAQMFAAAAAAAAAAEAESExQDBRcUFhgaEgEHCxwdHh8PH/2gAIAQEAAT8h+0n+NCF0eMpKR8xvj6iyhx9bE8kVx8GERk0cZFY/KAIEg+Zu3SwpGSYnsSAAAkGjWC22JLeR06qWqwu5zqc4YQnqJnxYS9+o5cWF2qdSibpYcv3KOnTlqcOqt14GZM0bJfbF/vsoESYzPnWVeghndxr0psxvb3gQTEfrYMjpjywimpuSf2UGz8o/n55PUbvBb3Y+NqwB5jdTtFUp+4RGSScMKkE2COowACRojU+YrV9+CICaxurrdRJlY96m2uE2ReAq3319wPrWm4EFbDDN0tRQLsEQsYM8i5R1JjelDCB1ZpAmDc0+RVw+YV0zI7Bhmr207GH+rp+th3eXy//aAAwDAQACAAMAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAU88MgAAAAAAAAAA88888AAAAAAAAAc88888gAAAAAAAA888888AAAAAAAAAA08888gAAAAAAAAAg088QAAAAAAAAAAMMMEEAAAAAAAAAUc888sEAAAAAAA88888888IAAAAAQc88888884AAAAAU888888888gAAAAQ888888888gAA//EABQRAQAAAAAAAAAAAAAAAAAAAHD/2gAIAQMBAT8QYf/EABQRAQAAAAAAAAAAAAAAAAAAAHD/2gAIAQIBAT8QYf/EACkQAQABAgQFBAMBAQAAAAAAAAERACEwMUBBUWGBkaFxscHhECDwcPH/2gAIAQEAAT8Q/wAjLsF3lQhIvXXnaRqr9IZqwdaJFPAyodBfJH4Sc6ObngQ+KEYzrdHekQIWRITTXEg9eQoo1kB+7VsRZ9niVuBEaRyuBd8ChLAgDbBKBtzzctJJk/iDthghRbeu/wDc9FwdMfSixbLDyBcHo20VxbS+MSL87ooJNweMSZ85opZyFfTejDmZ3D5Ojmaz47DuZPmb6NCkyz80AIIkib4JvIyTw50qsrK6RIIryf7lRoSXEc/3kikLOb9UhUrscjTN52/K+qIBvByd6jCOIz+RLlwm/alRi8v2KTsXNWV1MmRLiX4pQ2KSmYUJDch56hW8N1YOtDBVeid6ytPFJe7QAWt+RIF5JqQhcRx4yqRU4GVGSgzEhNGJcjABdoQ4oDI9eNAgAMgMsGKyuwsnWkeiO3rodgsipBZD6TliAgBGyNXBrm/hljoAKmAN6kYHPcORjIJDcqy9/u4Y0xKxaXl0BXSUNZ0iz4mziZwbHpQmwEGhjl7I/fviROseo/Xvosk9VS5iEemHOt2vR27kTv8A+YTlUJ7Lxo4+LR2fvCcq8A0eT1fDCcmvEe2j8H4ft//Z';


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
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Prevent back navigation if loading
          return !loading;
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !loading,
            backgroundColor: GlobalColor.AppBarCol,
          ),
          body: loading
              ? LoadingScreen()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ユーザー登録',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 40),

                        // Profile Picture and Edit Icon
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: imageFile != null &&
                                      imageFile!.isNotEmpty
                                  ? Image.memory(base64Decode(imageFile!)).image
                                  : null, // Add a default image if none is selected
                              child: imageFile == null || imageFile!.isEmpty
                                  ? Icon(Icons.person, size: 60)
                                  : null, // Show an icon if no image is selected
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  final String? image =
                                      await getImageFromGallery();
                                  if (image != null) {
                                    setState(() {
                                      imageFile = image;
                                    });
                                  }
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  radius: 20,
                                  child: Icon(Icons.edit, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 40),

                        // User ID and Username Fields
                        buildProfileField(
                          context,
                          label: 'ユーザーID',
                          controller: uidController,
                          restrictInput: true,
                          hint: 'ユーザーIDを入力してください',
                        ),
                        SizedBox(height: 20), // Add space between fields
                        buildProfileField(
                          context,
                          label: 'ユーザー名',
                          controller: usernameController,
                          restrictInput: false,
                          hint: 'ユーザー名を入力してください',
                        ),

                        SizedBox(height: 40), // More space before the button

                        // Register Button (Make it larger and more prominent)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 16.0), // Increase button height
                              backgroundColor:
                                  GlobalColor.MainCol, // Button color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    8.0), // Rounded corners
                              ),
                            ),
                            onPressed: () async {
                              if (uidController.text.isEmpty ||
                                  usernameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("すべての項目を入力してください"),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                loading = true; // Show loading screen
                              });

                              try {
                                // Check if the user ID already exists
                                await GetUser().getUser(uidController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("このuidはすでに使われています"),
                                  ),
                                );
                              } catch (e) {
                                // If the user doesn't exist, create a new one
                                if (imageFile != null) {
                                  userInformation.uicon = imageFile!;
                                }

                                try {
                                  // This is the time-consuming operation
                                  await CreateUser().createUser(UserInformation(
                                    google_uid: widget.result.id,
                                    uid: uidController.text,
                                    uname: usernameController.text,
                                    uicon: userInformation.uicon,
                                    refreshToken: widget.refresh_token,
                                    mailAddress: widget.result.email,
                                  ));

                                  // Navigate back after user creation
                                  Navigator.pop(context, userInformation);
                                } catch (e) {
                                  // Handle any errors during user creation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("ユーザー登録に失敗しました"),
                                    ),
                                  );
                                }
                              } finally {
                                setState(() {
                                  loading = false; // Hide loading screen
                                });
                              }
                            },
                            child: Text("登録",
                                style: TextStyle(
                                    fontSize: 22, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ));
  }
}

Widget buildProfileField(
  BuildContext context, {
  required String label,
  required String hint,
  required TextEditingController controller,
  required bool restrictInput,
}) {
  // Restrict input to 15 characters and apply filter if necessary
  controller.addListener(() {
    final text = controller.text;
    if (text.length > 15) {
      controller.text = text.substring(0, 15);
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  });

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label text above the text field
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        // Input field for entering text
        TextField(
          maxLength: 15,
          controller: controller,
          style: TextStyle(fontSize: 18),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide:
                  BorderSide(color: Colors.grey), // Unfocused border color
            ),
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          // Restrict input to alphanumeric and underscores if necessary
          inputFormatters: restrictInput
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ]
              : [],
        ),
      ],
    ),
  );
}
