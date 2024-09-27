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
class ChatL10nJa extends ChatL10n {
  const ChatL10nJa({
    String attachmentButtonAccessibilityLabel = '画像アップロード',
    String emptyChatPlaceholder = 'メッセージがありません。',
    String fileButtonAccessibilityLabel = 'ファイル',
    String inputPlaceholder = 'メッセージを入力してください',
    String sendButtonAccessibilityLabel = '送信',
    String and = 'そして',
    String isTyping = '入力中...',
    String others = '他のユーザー',
    String unreadMessagesLabel = '未読メッセージ',
  }) : super(
    attachmentButtonAccessibilityLabel: attachmentButtonAccessibilityLabel,
    emptyChatPlaceholder: emptyChatPlaceholder,
    fileButtonAccessibilityLabel: fileButtonAccessibilityLabel,
    inputPlaceholder: inputPlaceholder,
    sendButtonAccessibilityLabel: sendButtonAccessibilityLabel,
    and: and,
    isTyping: isTyping,
    others: others,
    unreadMessagesLabel: unreadMessagesLabel,
  );
}
class _ChatScreenState extends State<ChatScreen> {
  final List<types.Message> _messages = [];
  static const getMessageLimit = 15;
  static const bool debuglog = false;
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
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        if (lastMessageId != '0') {
          if (getMsgStatus != "running"){
            getNewMessages();
          }
        }else{
          getMessages();
        }
        setState(() {});
      }
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
              l10n: const ChatL10nJa(),
              hideBackgroundOnEmojiMessages: false,
              theme: DefaultChatTheme(
                backgroundColor: GlobalColor.backGroundCol,
                userAvatarNameColors: [
                  GlobalColor.MainCol,
                ],
                primaryColor: GlobalColor.ChatCol,
                sentMessageBodyTextStyle: TextStyle(
                  color: Colors.black87,
                ),
                messageInsetsVertical: 10, // Adjust vertical padding
                messageInsetsHorizontal: 15, // Adjust horizontal padding
              ),

            )

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
      log("getNewMsgは実行中のため、実行できません。");
      return;
    }
    getNewMsgStatus = "running";
    try{
      log("getNewMessagesが実行開始されました。");
      List<ChatMessage> messages = await GetChatNewMessage().getChatNewMessage(
          widget.gid!, getMessageLimit, latestMessageId,Provider.of<UserData>(context, listen: false).uid!);
      log("getNewMessagesの取得件数："+messages.length.toString());
      if (messages.length == 0) {
        getNewMsgStatus = "success";
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
      log("getNewMessagesが正常に終了しました。");
    }catch(e){
      getNewMsgStatus = "failed";
      log("getNewMessagesでエラーが発生しました。");
      print(e);
    }
  }

  Future<void> getMessages() async{
    if(getMsgStatus == "running"){
      log("getMessagesは実行中のため、実行できません。");
      return;
    }
    getMsgStatus = "running";
    try{
      log("getMessagesが実行開始されました。");
      List<ChatMessage> messages = await GetChatMessages().getChatMessages(widget.gid!, lastMessageId,getMessageLimit,Provider.of<UserData>(context, listen: false).uid!);
      log("getMessagesの取得件数："+messages.length.toString());
      if(messages.length == 0){
        getMsgStatus = "success";
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
    } catch(e){
      getMsgStatus = "failed";
      log("getMessagesでエラーが発生しました。");
      print(e);
    }
  }
  void log(String message){
    if(debuglog){
      print(message);
    }
  }
}