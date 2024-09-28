import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/APIcalls.dart';
import '../services/UserData.dart';
import '../setting/color.dart' as GlobalColor;
import 'package:provider/provider.dart';

class AddFriendNearby extends StatefulWidget {
  final String myUid;

  const AddFriendNearby({Key? key, required this.myUid}) : super(key: key);

  @override
  _AddFriendNearbyState createState() => _AddFriendNearbyState();
}

class _AddFriendNearbyState extends State<AddFriendNearby> {
  final Nearby _nearby = Nearby();
  List<Device> discoveredDevices = [];
  bool isDiscovering = false;
  bool isAdvertising = false;
  final Strategy strategy = Strategy.P2P_CLUSTER;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStart();
  }

  @override
  void dispose() {
    _stopNearbyServices();
    super.dispose();
  }

  Future<void> _checkPermissionsAndStart() async {
    if (await _checkPermissions()) {
    } else {
      _showErrorSnackBar("Permissions not granted");
    }
  }

  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      print("Not all permissions granted.");
    }
    return allGranted;
  }

  void _startNearbyServices() async {
    // Start Advertising
    await _startAdvertising();

    // Start Discovery after Advertising has started
    await _startDiscovery();
  }

  Future<void> _startAdvertising() async {
    if (isAdvertising) {
      print("Already advertising.");
      return;
    }

    try {
      print("Starting Advertising...");
      bool advertising = await _nearby.startAdvertising(
        widget.myUid,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          print("Connection result: $id, $status");
        },
        onDisconnected: (id) {
          print("Disconnected: $id");
        },
      );

      if (advertising) {
        setState(() {
          isAdvertising = true;
        });
        print("Advertising started successfully.");
      } else {
        print("Advertising failed to start.");
        _showErrorSnackBar("Advertising failed to start.");
      }
    } catch (e) {
      print("Failed to start advertising: $e");
      _showErrorSnackBar("Failed to start advertising: ${e.toString()}");
    }
  }

  Future<void> _stopAdvertising() async {
    if (!isAdvertising) {
      print("Not currently advertising.");
      return;
    }

    try {
      print("Stopping Advertising...");
      await _nearby.stopAdvertising();
      if(!mounted) return;
      setState(() {
        isAdvertising = false;
      });
      print("Advertising stopped.");
    } catch (e) {
      print("Failed to stop advertising: $e");
      _showErrorSnackBar("Failed to stop advertising: ${e.toString()}");
    }
  }

  Future<void> _startDiscovery() async {
    if (isDiscovering) {
      print("Already discovering.");
      _showErrorSnackBar("Discovery is already running.");
      return;
    }

    setState(() {
      isDiscovering = true;
      discoveredDevices.clear();
    });

    try {
      print("Starting Discovery...");
      bool discovering = await _nearby.startDiscovery(
        widget.myUid,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          print("Endpoint found: $id, $name, $serviceId");
          if (!mounted) return; // Ensure the widget is still mounted

          // Access the friends list from Provider
          List<FriendInformation> friends = Provider.of<UserData>(context, listen: false).friends;

          // Check if the discovered device is already a friend
          bool isAlreadyFriend = friends.any((friend) => friend.uid == id);

          if (!isAlreadyFriend) {
            setState(() {
              // Check if the device is already in the list to prevent duplicates
              if (!discoveredDevices.any((device) => device.id == id)) {
                discoveredDevices.add(Device(id, name));
              }
            });
          } else {
            print("Device $id is already a friend. Skipping display.");
          }
        },
        onEndpointLost: (id) {
          print("Endpoint lost: $id");
          setState(() {
            discoveredDevices.removeWhere((d) => d.id == id);
          });
        },
      );

      if (discovering) {
        print("Discovery started successfully.");
      } else {
        print("Discovery failed to start.");
        _showErrorSnackBar("Discovery failed to start.");
        setState(() {
          isDiscovering = false;
        });
      }
    } catch (e) {
      print("Discovery failed: $e");
      _showErrorSnackBar("Discovery failed: ${e.toString()}");
      setState(() {
        isDiscovering = false;
      });
    }
  }

  Future<void> _stopDiscovery() async {
    if (!isDiscovering) {
      print("Not currently discovering.");
      return;
    }

    try {
      print("Stopping Discovery...");
      await _nearby.stopDiscovery();
      if(!mounted) return;
      setState(() {
        isDiscovering = false;
      });
      print("Discovery stopped.");
    } catch (e) {
      print("Failed to stop discovery: $e");
      _showErrorSnackBar("Failed to stop discovery: ${e.toString()}");
    }
  }

  Future<void> _stopNearbyServices() async {
    await _stopAdvertising();
    await _stopDiscovery();
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    print("Connection initiated with $id (${info.endpointName})");
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async { // Corrected parameter name
        if (payload.bytes != null) {
          String friendUid = String.fromCharCodes(payload.bytes!);
          print("Received payload: $friendUid");
          await _addFriend(friendUid);
        } else {
          print("Received empty payload.");
        }
      },
    );
  }


  void _connectToDevice(Device device) async {
    try {
      print("Requesting connection to ${device.id} (${device.name})");
      await _nearby.requestConnection(
        widget.myUid,
        device.id,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          print("Connection result: $id, $status");
          if (status == Status.CONNECTED) {
            _nearby.sendBytesPayload(id, Uint8List.fromList(widget.myUid.codeUnits));
            print("Sent UID payload to $id");
          }

        },
        onDisconnected: (id) {
          print("Disconnected from: $id");
        },
      );
    } catch (e) {
      print("Connection failed: $e");
      _showErrorSnackBar("Connection failed: ${e.toString()}");
    }
  }

  Future<void> _addFriend(String friendUid) async {
    try {
      print("Adding friend with UID: $friendUid");
      await AddFriendDirectly().addFriend(widget.myUid, friendUid);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('フレンドが追加されました')));
    } catch (e) {
      print("Failed to add friend: $e");
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
      body: Padding( // Optional: Add padding for better UI
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              '近くのデバイスでフレンドを追加する',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // Optional: Center the text
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: isDiscovering ? _stopNearbyServices : _startDiscovery,
              child: Text(
                isDiscovering ? 'デバイスを探しています...' : 'デバイスを探す',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColor.MainCol,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Optional: Button styling
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),

            Expanded(
              child: discoveredDevices.isEmpty
                  ? Center(child: Text('デバイスが見つかりませんでした。'))
                  : ListView.builder(
                itemCount: discoveredDevices.length,
                itemBuilder: (context, index) {
                  Device device = discoveredDevices[index];
                  return FutureBuilder<UserInformation>(
                    future: GetUser().getUser(device.id), // Fetch user info
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text(device.id),
                          trailing: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text('Error fetching user'),
                          trailing: Icon(Icons.error, color: Colors.red),
                        );
                      } else if (snapshot.hasData) {
                        UserInformation foundUser = snapshot.data!;
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            _connectToDevice(device);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: GlobalColor.ItemCol,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey,
                                  width: 0.2,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
// User Icon
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.white,
                                      backgroundImage: NetworkImage(
                                        "https://calendar-files.woody1227.com/user_icon/${foundUser.uicon}",
                                      ),
                                    ),
                                    SizedBox(width: 20),
// User Name and UID
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          foundUser.uname,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        Text(
                                          "@${foundUser.uid}",
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.black.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text(device.id),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Device {
  final String id;
  final String name;

  Device(this.id, this.name);
}
