import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String? gid;
  ChatScreen({required this.gid});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<types.Message> _messages = [];
  static const getMessageLimit = 15;
  String lastMessageId = '0';
  String latestMessageId = '0';
  late types.User myUser;
  @override
  void initState() {
    super.initState();
    final userData = Provider.of<UserData>(context, listen: false);
    myUser = types.User(
      firstName: userData.uname,
      id: userData.uid!,
      imageUrl: userData.uicon,
    );
    getMessages();
    //3秒毎に呼ぶ
    Timer.periodic(Duration(milliseconds: 1000), (timer) {
      setState(() {});
      getNewMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
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
    UserData userData = Provider.of<UserData>(context, listen: false);
    await SendChatMessage().sendChatMessage(widget.gid!,userData.uid, message.text);
  }

  void _addMessage(types.Message message,[bool isMe = false]) {
    if (mounted){
      if (isMe) {
        _messages.insert(0, message);
      } else {
        _messages.add(message);
      }
    }
  }

  Future<void> getNewMessages() async {
    List<ChatMessage> messages = await GetChatNewMessage().getChatNewMessage(
        widget.gid!, getMessageLimit, latestMessageId);
    if (messages.length == 0) {
      return;
    }
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].mid == latestMessageId) {
        continue;
      }
      final message = messages[i];
      //flutter_chat_uiのMessage型に変換
      final Message_author = types.User(
        firstName: message.uname,
        id: message.uid,
        imageUrl: "https://calendar-files.woody1227.com/user_icon/" + message.uicon,
      );
      final newMessage = types.TextMessage(
        author: Message_author,
        id: message.mid,
        text: message.content,
      );
      _addMessage(newMessage, true);
    }
    latestMessageId = messages.last.mid;
  }

  Future<void> getMessages() async{
    List<ChatMessage> messages = await GetChatMessages().getChatMessages(widget.gid!, getMessageLimit, lastMessageId);
    if(messages.length == 0){
      return;
    }
    //メッセージを逆転
    messages = messages.reversed.toList();
    for(int i = 0; i < messages.length; i++) {
      if (messages[i].mid == lastMessageId) {
        continue;
      }
      final message = messages[i];
      //flutter_chat_uiのMessage型に変換
      final Message_author = types.User(
        firstName: message.uname,
        id: message.uid,
        imageUrl: "https://calendar-files.woody1227.com/user_icon/"+message.uicon,
      );
      final newMessage = types.TextMessage(
        author: Message_author,
        id: message.mid,
        text: message.content,
      );
      _addMessage(newMessage);
    }
    if (lastMessageId == '0' && messages.isNotEmpty){
      latestMessageId = messages.first.mid;
    }
    lastMessageId = messages.last.mid;
  }
}