import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:provider/provider.dart';

class ReadQR extends StatefulWidget {
  const ReadQR({Key? key}) : super(key: key);

  @override
  _ReadQRState createState() => _ReadQRState();
}

class _ReadQRState extends State<ReadQR> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool friendAddStatus = false;
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
                ),
                Positioned(
                  top: 20,
                  left: 20,
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
              child: Text(
                'QRコードを読み取ってフレンドを追加',
                style: const TextStyle(fontSize: 20),
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
      if (scanData.code!.length <= 7 && scanData.format != BarcodeFormat.qrcode){
        return;
      }
      if (scanData.code!.substring(0, 7) != 'sando//'){
        return;
      }
      if (friendAddStatus) {
        return;
      }
      //apiを叩いてフレリクを送信
      String? uid = Provider.of<UserData>(context, listen: false).uid;
      String friendUid = scanData.code!.substring(7);
      sendFriendRequest(uid!, friendUid);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  //フレンドリクエストを送信する
  void sendFriendRequest(String uid, String friendUid) async {
    friendAddStatus = true;
    try{
      await AddFriendRequest().addFriend(uid, friendUid);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('フレンドの追加'),
            content: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
                Text('フレンド申請を送信しました'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  friendAddStatus = false;
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error sending friend request: $e');
      if (e.toString() == "Failed to add friend: 404") {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('フレンドの追加'),
              content: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 50,
                  ),
                  Text('ユーザーが見つかりませんでした',
                      style: const TextStyle(fontSize: 20)),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    friendAddStatus = false;
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else if (e.toString() == "Failed to add friend: 409") {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('フレンドの追加'),
              content: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 50,
                  ),
                  Text('すでにフレンド申請を送信しています',
                      style: const TextStyle(fontSize: 20)),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    friendAddStatus = false;
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }
  }
}