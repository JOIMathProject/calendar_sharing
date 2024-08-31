import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:calendar_sharing/setting/color.dart' as GlobalColor;

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
  String getNewMsgStatus = "";
  String getMsgStatus = "";
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
      if (mounted) {
        if (lastMessageId != '0') {
          if (getMsgStatus != "running"){
            getNewMessages();
          }
        }else{
          getMessages();
        }
      }else{
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
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
              theme: DefaultChatTheme(
                userAvatarNameColors: [
                  GlobalColor.MainCol,
                ],
                primaryColor: GlobalColor.MainCol,
              ),
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
    if (getNewMsgStatus == "running") {
      return;
    }
    getNewMsgStatus = "running";
    List<ChatMessage> messages = await GetChatNewMessage().getChatNewMessage(
        widget.gid!, getMessageLimit, latestMessageId,Provider.of<UserData>(context, listen: false).uid!);
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
        createdAt: message.sendTime.millisecondsSinceEpoch,
      );
      _addMessage(newMessage, true);
    }
    latestMessageId = messages.last.mid;
    getNewMsgStatus = "success";
  }

  Future<void> getMessages() async{
    if(getMsgStatus == "running"){
      return;
    }
    getMsgStatus = "running";
    List<ChatMessage> messages = await GetChatMessages().getChatMessages(widget.gid!, lastMessageId,getMessageLimit,Provider.of<UserData>(context, listen: false).uid!);
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
        createdAt: message.sendTime.millisecondsSinceEpoch,
      );
      _addMessage(newMessage);
    }
    if (lastMessageId == '0' && messages.isNotEmpty){
      latestMessageId = messages.first.mid;
    }
    lastMessageId = messages.last.mid;
    getMsgStatus = "success";
  }
}