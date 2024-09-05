import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

class UserinfoIcon{
  UserInformation userInformation;
  XFile? imageFile;
  UserinfoIcon({required this.userInformation, required this.imageFile});
}

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});
  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  UserinfoIcon userInformation = UserinfoIcon(
    userInformation: UserInformation(
      uid: "",
      uname: "",
      uicon: "",
      refreshToken: "",
      mailAddress: "",
      google_uid: "",
    ),
    imageFile: null
  );
  final imagePicker = ImagePicker();
  XFile? imageFile;
  Future<XFile?> getImageFromGallery() async {
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await File(pickedFile.path).readAsBytes();
      final image = img.decodeImage(imageBytes);

      // Check if the image needs to be rotated
      final rotatedImage = img.bakeOrientation(image!);

      // Encode the corrected image
      final correctedBytes = img.encodeJpg(rotatedImage);

      // Save the corrected image to a temporary file
      final correctedFile = await File(pickedFile.path).writeAsBytes(correctedBytes);

      return XFile(correctedFile.path);
    }

    return null;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("登録する",style: TextStyle(fontSize: 20),),
            SizedBox(height: 20),
            //アイコンとuidとunameの入力をする画面を構築する
            CircleAvatar(
              backgroundImage: imageFile == null ? const NetworkImage('https://calendar-files.woody1227.com/user_icon/default.png') : FileImage(File(imageFile!.path)),
              radius: 50,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final XFile? image = await getImageFromGallery();
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
                userInformation.userInformation.uid = value;
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: "name",
                hintText: "山田太郎",
              ),
              onChanged: (value) {
                userInformation.userInformation.uname = value;
              },
            ),
            ElevatedButton(
              onPressed: () async{
                //すべてが入力されているかどうか、uidが存在するかどうかを確認後、できていたらreturn
                if (userInformation.userInformation.uid == "" || userInformation.userInformation.uname == "") {
                  //画面下にエラーを出す
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("すべての項目を入力してください"),
                    ),
                  );
                  //uidがすでに存在するかどうか
                  try{
                    await GetUser().getUser(userInformation.userInformation.uid);
                  } catch (e){
                    //uidが存在する(404の)場合、エラーを出す
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("このuidはすでに使われています"),
                      ),
                    );
                    return;
                  }
                  if (imageFile != null){
                    userInformation.imageFile = imageFile;
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