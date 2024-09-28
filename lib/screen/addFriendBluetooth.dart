import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/APIcalls.dart';
import '../setting/color.dart' as GlobalColor;

class AddFriendBluetooth extends StatefulWidget {
  final String myUid;

  const AddFriendBluetooth({Key? key, required this.myUid}) : super(key: key);

  @override
  _AddFriendBluetoothState createState() => _AddFriendBluetoothState();
}

class _AddFriendBluetoothState extends State<AddFriendBluetooth> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<bool>? scanningSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    scanningSubscription?.cancel();
    super.dispose();
  }

  void _checkBluetoothState() async {
    try {
      if (await FlutterBluePlus.isAvailable == false) {
        throw Exception("Bluetooth not available on this device");
      }

      if (await FlutterBluePlus.isOn) {
        _startScan();
      } else {
        await FlutterBluePlus.turnOn();
        _startScan();
      }
    } catch (e) {
      _showErrorSnackBar("Bluetooth error: ${e.toString()}");
    }
  }

  void _startScan() {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    try {
      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      }, onError: (e) => _showErrorSnackBar("Scan error: ${e.toString()}"));

      scanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
        setState(() {
          isScanning = scanning;
        });
      });

      FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    } catch (e) {
      _showErrorSnackBar("Failed to start scan: ${e.toString()}");
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(utf8.encode(widget.myUid));
          }
          if (characteristic.properties.read) {
            List<int> value = await characteristic.read();
            String friendUid = utf8.decode(value);
            _addFriend(friendUid);
          }
        }
      }

      await device.disconnect();
    } catch (e) {
      _showErrorSnackBar("Connection error: ${e.toString()}");
    }
  }

  void _addFriend(String friendUid) async {
    try {
      await AddFriendRequest().addFriend(widget.myUid, friendUid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('フレンドが追加されました')),
      );
    } catch (e) {
      _showErrorSnackBar("フレンドの追加に失敗しました: ${e.toString()}");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalColor.AppBarCol,
      ),
      body: Column(
        children: [
          SizedBox(height: 50),
          Text('Bluetoothでフレンドを追加する', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: isScanning ? null : _startScan,
            child: Text(isScanning ? 'スキャン中...' : 'デバイスをスキャン', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor:  GlobalColor.MainCol),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                ScanResult result = scanResults[index];
                return ListTile(
                  title: Text(result.device.name.isNotEmpty
                      ? result.device.name
                      : '不明のデバイス'),
                  subtitle: Text(result.device.remoteId.toString()),
                  onTap: () => _connectToDevice(result.device),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}