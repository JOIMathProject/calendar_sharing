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

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  void _checkBluetoothState() async {
    if (await FlutterBluePlus.isOn) {
      _startScan();
    } else {
      // Request to turn on Bluetooth
      // This might not work on iOS due to restrictions
      await FlutterBluePlus.turnOn();
    }
  }

  void _startScan() {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      setState(() {
        isScanning = scanning;
      });
    });
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
      print('Error connecting to device: $e');
    }
  }

  void _addFriend(String friendUid) async {
    try {
      await AddFriendRequest().addFriend(widget.myUid, friendUid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('フレンドが追加されました')),
      );
    } catch (e) {
      print('Error adding friend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('フレンドの追加に失敗しました。')),
      );
    }
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
            child: Text(isScanning ? 'スキャン中...' : 'デバイスをスキャン',style: TextStyle(color: Colors.white)),
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