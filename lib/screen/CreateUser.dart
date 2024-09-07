import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});
  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  UserInformation userInformation = UserInformation(
    uid: "",
    uname: "",
    uicon: "",
    refreshToken: "",
    mailAddress: "",
    google_uid: "",
  );
  final imagePicker = ImagePicker();

  String? imageFile = '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';
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              "登録する",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            //アイコンとuidとunameの入力をする画面を構築する
            CircleAvatar(
              backgroundImage: Image.memory(base64Decode(imageFile!))?.image,
              radius: 50,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final String? image = await getImageFromGallery();
                if (image != null) {
                  setState(() {
                    imageFile = image;
                  });
                }
              },
              child: Text("アイコンを選択"),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "@",
              ),
              onChanged: (value) {
                userInformation.uid = value;
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: "name",
                hintText: "山田太郎",
              ),
              onChanged: (value) {
                userInformation.uname = value;
              },
            ),
            ElevatedButton(
              onPressed: () async {
                //すべてが入力されているかどうか、uidが存在するかどうかを確認後、できていたらreturn
                if (userInformation.uid == "" ||
                    userInformation.uname == "") {
                  //画面下にエラーを出す
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("すべての項目を入力してください"),
                    ),
                  );
                  //uidがすでに存在するかどうか
                  try {
                    await GetUser()
                        .getUser(userInformation.uid);
                  } catch (e) {
                    //uidが存在する(404の)場合、エラーを出す
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("このuidはすでに使われています"),
                      ),
                    );
                    return;
                  }
                  if (imageFile != null) {
                    userInformation.uicon = imageFile!;
                  }
                  return;
                }
                Navigator.pop(context, userInformation);
              },
              child: Text("登録"),
            ),
          ],
        ),
      ),
    );
  }
}
