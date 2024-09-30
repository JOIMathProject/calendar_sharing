import "package:flutter/material.dart";
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../setting/color.dart' as GlobalColor;

class ReadQR extends StatefulWidget {
  const ReadQR({super.key});

  @override
  _ReadQRState createState() => _ReadQRState();
}

class _ReadQRState extends State<ReadQR> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool friendAddStatus = false;
  bool SnackBarStatus = false;
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    //platformはandroid
    controller!.pauseCamera();
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = Provider.of<UserData>(context, listen: false).uid;
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.white,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 30,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                children: [
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'QRコードを読み取る',
                      style:
                          TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 50,
                            color: GlobalColor.SubCol,
                          ),
                          Text('自分のQRを表示', style: TextStyle(color: GlobalColor.SubCol)),
                        ],
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return MyQRModal(uid: uid);
                          });
                    },
                  ),
                  const Spacer(flex: 2,),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code!.length <= 7 &&
          scanData.format != BarcodeFormat.qrcode) {
        return;
      }
      if (scanData.code!.substring(0, 7) != 'sando//') {
        return;
      }
      if (friendAddStatus) {
        return;
      }
      //apiを叩いてフレリクを送信
      String? uid = Provider.of<UserData>(context, listen: false).uid;
      String friendUid = scanData.code!.substring(7);
      checkFriendRequest(uid!, friendUid);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void checkFriendRequest(String uid, String friendUid) async {
    friendAddStatus = true;
    if (friendUid == uid) {
      FriendAddSnackBar(context,"自分自身をフレンドに追加することはできません",const Icon(
        Icons.error,
        color: Colors.red,
      ));
      friendAddStatus = false;
      return;
    }
    //本当にフレンドリクエストを送信するかどうかの確認画面
    try {
      final UserInformation friendInfo = await GetUser().getUser(friendUid);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async {
              friendAddStatus = false;
              return true;
            },
            child: AlertDialog(
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 50),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage("https://calendar-files.woody1227.com/user_icon/${friendInfo.uicon}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          friendInfo.uname,
                          style: const TextStyle(fontSize: 25),
                        ),
                        Text(
                          "@${friendInfo.uid}",
                          style: const TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    child: const Text(
                      'フレンドリクエストを\n送信しますか？',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '相手がフレンドリクエストを承認すると自動的にフレンドに追加されます。',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    friendAddStatus = false;
                  },
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    addFriend(uid, friendUid);
                    Navigator.of(context).pop();
                  },
                  child: Text('送信',style: TextStyle(color: GlobalColor.MainCol),),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error checking friend request: $e');
      if (e.toString() == "Failed to get user: 404") {
        FriendAddSnackBar(context,"ユーザーが見つかりません",const Icon(
          Icons.error,
          color: GlobalColor.SubCol,
        ));
      } else {
        FriendAddSnackBar(context,"エラーが発生しました。",const Icon(
          Icons.error,
          color: GlobalColor.SubCol,
        ));
      }
      return;
    }
  }


  void addFriend(String myUid, String friendUid) async{
    //snackを使用して、フレンドリクエストを送信しましたと表示
    try {
      await AddFriendRequest().addFriend(myUid, friendUid);
      FriendAddSnackBar(context,"フレンドリクエストを送信しました",const Icon(
        Icons.check_circle,
        color: GlobalColor.SubCol,
      ));
    } catch (e) {
      print('Error sending friend request: $e');
      if (e.toString() == "Failed to add friend: 404") {
        FriendAddSnackBar(context,"ユーザーが見つかりません",const Icon(
          Icons.error,
          color: GlobalColor.SubCol,
        ));
      } else if (e.toString() == "Failed to add friend: 409") {
        FriendAddSnackBar(context,"既にフレンドリクエストを送信しています",const Icon(
          Icons.error,
          color: GlobalColor.SubCol,
        ));
      }
      return;
    }
  }

  void FriendAddSnackBar(BuildContext context,String msg,Icon icon) {
    if (SnackBarStatus) {
      return;
    }
    SnackBarStatus = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GlobalColor.SnackCol,
        content: Row(
          children: [
            icon,
            Container(
              margin: const EdgeInsets.only(left: 10),
                child: Text(msg,style: TextStyle(color: GlobalColor.SubCol))
            ),
          ],
        ),
      ),
    );
    friendAddStatus = false;
    Future.delayed(const Duration(seconds: 4), () {
      SnackBarStatus = false;
    });
  }
}

class MyQRModal extends StatelessWidget {
  const MyQRModal({
    super.key,
    required this.uid,
  });

  final String? uid;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          //モーダル自体の色
          color: Colors.white,
          //角丸にする
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Expanded(
                flex: 7,
                child: Center(
                  child: QrImageView(
                    data: 'sando//$uid',
                  ),
                ),
              ),
              const Spacer(),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Text(
                      '@$uid',
                      style: const TextStyle(
                        fontSize: 30,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'このQRコードを友達に読み込んでもらうと、\n友達追加ができます',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
