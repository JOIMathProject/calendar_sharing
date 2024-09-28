import "package:flutter/material.dart";
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:calendar_sharing/services/APIcalls.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReadQR extends StatefulWidget {
  const ReadQR({super.key});

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
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 50,
                          ),
                          Text('自分のQRを表示'),
                        ],
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(context: context, builder:(BuildContext context) {
                        return MyQRModal(uid: uid);
                      });
                    },
                  ),
                  const Spacer(),
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
      String? uid = Provider
          .of<UserData>(context, listen: false)
          .uid;
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
    try {
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
        )
    );
  }
}