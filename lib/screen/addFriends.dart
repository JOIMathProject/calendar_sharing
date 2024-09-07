import 'package:flutter/material.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;

class AddFriend extends StatefulWidget {
  @override
  _AddFriendState createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    UserData userData = Provider.of<UserData>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.SubCol,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 1), // Adds flexible space at the top
            const Text(
              'フレンドリクエストを送る',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Spacer(flex: 1), // Adds space between the title and the TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: buildProfileField(
                        context,
                        label: 'ユーザーID',
                        hint: 'ユーザーIDを入力してください',
                        controller: _searchController,
                        restrictInput: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 5), // Adds more space between the TextField and the button
            Padding(
              padding: const EdgeInsets.all(16.0), // Adjust padding as needed
              child: SizedBox(
                height: 50,
                width: 400,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  onPressed: () {
                    Future<void> addFriend = AddFriendRequest()
                        .addFriend(userData.uid!, _searchController.text);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return addFriendResultDialog(addFriend);
                      },
                    );
                  },
                  child: Text(
                    'フレンドリクエストを送る',
                    style: TextStyle(fontSize: 20, color: GlobalColor.SubCol),
                  ),
                ),
              ),
            ),
            Spacer(flex: 1), // Adds space at the bottom for better balancing
          ],
        ),
      ),
    );
  }

  AlertDialog addFriendResultDialog(Future<void> addFriend) {
    return AlertDialog(
      title: const Text('フレンドの追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<void>(
            future: addFriend,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.waiting && !snapshot.hasError) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                    Text('フレンド申請を送信しました'),
                  ],
                );
              } else if (snapshot.hasError) {
                if (snapshot.error == 'Failed to add friend: 409') {
                  return const Column(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                      Text('すでにフレンドもしくは\n送信済みです', style: TextStyle(fontSize: 20)),
                    ],
                  );
                }else if(snapshot.error == 'Failed to add friend: 404'){
                  return const Column(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                      Text('ユーザーが見つかりません', style: TextStyle(fontSize: 20)),
                    ],
                  );

                } else {
                  return Column(
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                      Text('エラーが発生しました'),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      )
                    ],
                  );
                }
              }
              return CircularProgressIndicator();
            },
          ),
        ],
      ),
      actions: [
        closeButton(),
      ],
    );
  }
}

class closeButton extends StatelessWidget {
  const closeButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: Text('閉じる'),
    );
  }
}
Widget buildProfileField(
    BuildContext context, {
      required String label,
      required String hint,
      required TextEditingController controller,
      required bool restrictInput,
    }) {

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
          maxLength: 15, // Total length without @
          controller: controller,
          style: TextStyle(fontSize: 18),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey), // Unfocused border color
            ),
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            // Adding @ as a non-editable prefix
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 5.0),
              child: Text(
                '@',
                style: TextStyle(fontSize: 18),
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                controller.clear();
              },
            )
                : null,
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

