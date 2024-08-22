import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String? gid;
  ChatScreen({required this.gid});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<types.Message> _messages = [];
  static const getMessageLimit = 10;
  UserData? userData;
  String lastMessageId = '';
  //FIXME myUserをどうやって定義するか問題
  types.User myUser = types.User(
    id: '1',
  );

  @override
  void initState() {
    super.initState();
    getMessages();
  }

  @override
  Widget build(BuildContext context) {
    userData = Provider.of<UserData>(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Chat(
              messages: _messages,
              user: myUser,
              onSendPressed: sendMessage,
              onEndReached: getMessages,
              showUserAvatars: true,
              showUserNames: true,
            ),
          )
        ],
      ),
    );
  }
  void sendMessage(types.PartialText message) async{
    //先にAPI叩いてから
    //FIXME uidをどうやって取得するか問題
    try{
      final mid = await SendChatMessage().sendChatMessage(widget.gid!,"kuroinusan", message.text);
      final newMessage = types.TextMessage(
        id: mid,
        text: message.text,
        author: myUser,
      );
      _addMessage(newMessage);
    } catch(e){
      print(e);
    }
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<void> getMessages() async{
    final messages = await GetChatMessages().getChatMessages(widget.gid!, getMessageLimit, lastMessageId);
    if(messages.length == 0){
      return;
    }
    lastMessageId = messages.last.mid;
    for(int i = 0; i < messages.length; i++) {
      final message = messages[i];
      //flutter_chat_uiのMessage型に変換
      final Message_author = types.User(
        firstName: message.uname,
        id: message.uid,
        imageUrl: message.uicon,
      );
      final newMessage = types.TextMessage(
        author: Message_author,
        id: message.mid,
        text: message.content,
      );
      _addMessage(newMessage);
    }
  }
}