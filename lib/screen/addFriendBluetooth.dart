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
  Map<String, UserInformation?> cachedUserInfo = {}; // Cache for fetched user info
  final Strategy strategy = Strategy.P2P_CLUSTER;
  List<String> receivedFriendUid = []; // Initialize received UIDs
  List<String> sentFriendUid = []; // Initialize sent UIDs
  Set<String> connectedEndpoints = {}; // Track connected endpoints

  @override
  void initState() {
    super.initState();
    _disconnectFromAllEndpoints();
    _checkPermissionsAndStart();
  }

  @override
  void dispose() {
    _disconnectFromAllEndpoints(); // Disconnect when disposing
    _stopNearbyServices();
    super.dispose();
  }

  Future<void> _checkPermissionsAndStart() async {
    if (!await _checkPermissions()) {
      _showErrorSnackBar("Permissions not granted");
    }
  }
  void SendPayLoad(String id) {
    _nearby.sendBytesPayload(
      id,
      Uint8List.fromList(widget.myUid.codeUnits),
    );
    print("Sent UID payload to $id");
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

  // Disconnect from all connected endpoints
  Future<void> _disconnectFromAllEndpoints() async {
    try {
      await Nearby().stopAllEndpoints(); // Stops all active connections
    } catch (e) {
      print("Error disconnecting endpoints: $e");
    }
  }

  void _startNearbyServices() async {
    await _startAdvertising();
    await _startDiscovery();
  }

  Future<void> _startAdvertising() async {
    if (isAdvertising) return;

    try {
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
        _showErrorSnackBar("Advertising failed to start.");
      }
    } catch (e) {
      _showErrorSnackBar("Failed to start advertising: ${e.toString()}");
    }
  }

  Future<void> _startDiscovery() async {
    if (isDiscovering) return;

    setState(() {
      isDiscovering = true;
      discoveredDevices.clear();
      cachedUserInfo.clear(); // Clear previous cached data
    });
    try {
      bool discovering = await _nearby.startDiscovery(
        widget.myUid,
        strategy,
        onEndpointFound: (id, name, serviceId) async {
          // Fetch friends list outside of setState
          List<FriendInformation> friends = await GetFriends().getFriends(widget.myUid);

          // Once the friends list is fetched, update the UI
          setState(() {
            Device device = Device(id, name);
            // Add the device if it is not already in the friends list
            if (!friends.map((friend) => friend.uid).contains(device.name)) {
              discoveredDevices.add(device);
            }

            // Fetch user info if not already cached
            if (!cachedUserInfo.containsKey(device.name)) {
              _fetchAndCacheUserInfo(device.name);
            }
          });
        },
        onEndpointLost: (id) {
          setState(() {
            discoveredDevices.removeWhere((d) => d.id == id);
            cachedUserInfo.removeWhere((key, value) => key == id);
            connectedEndpoints.remove(id); // Remove from connected endpoints
          });
        },
      );

      if (!discovering) {
        _showErrorSnackBar("Discovery failed to start.");
        setState(() {
          isDiscovering = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar("Discovery failed: ${e.toString()}");
      setState(() {
        isDiscovering = false;
      });
    }

  }

  Future<void> _fetchAndCacheUserInfo(String userId) async {
    try {
      UserInformation userInfo = await GetUser().getUser(userId);
      setState(() {
        cachedUserInfo[userId] = userInfo; // Cache the user info
      });
    } catch (e) {
      setState(() {
        cachedUserInfo[userId] = null; // Cache null in case of error
      });
    }
  }

  Future<void> _stopNearbyServices() async {
    await _stopAdvertising();
    await _stopDiscovery();
  }

  Future<void> _stopAdvertising() async {
    if (!isAdvertising) return;

    try {
      await _nearby.stopAdvertising();
      if (!mounted) return;
      setState(() {
        isAdvertising = false;
      });
    } catch (e) {
      _showErrorSnackBar("Failed to stop advertising: ${e.toString()}");
    }
  }

  Future<void> _stopDiscovery() async {
    if (!isDiscovering) return;

    try {
      await _nearby.stopDiscovery();
      if (!mounted) return;
      setState(() {
        isDiscovering = false;
      });
    } catch (e) {
      _showErrorSnackBar("Failed to stop discovery: ${e.toString()}");
    }
  }
  void _onConnectionInitiated(String id, ConnectionInfo info) {
    print("Connection initiated with $id (${info.endpointName})");
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.bytes != null) {
          String friendUid = String.fromCharCodes(payload.bytes!);
          print("Received payload: $friendUid");

          if (sentFriendUid.contains(friendUid)) {
            sentFriendUid.remove(friendUid);
          } else {
            receivedFriendUid.add(friendUid);
          }

          // Send payload back to confirm receipt
          SendPayLoad(id);
          print("Sent acknowledgment payload to $id");

          if (receivedFriendUid.contains(friendUid)) {
            receivedFriendUid.remove(friendUid);
          }
        } else {
          print("Received empty payload.");
        }
      },
    );
  }

  void _connectToDevice(Device device) async {
    try {
      if (connectedEndpoints.contains(device.id)) {
        // Already connected, just send the payload
        SendPayLoad(device.id);
        print("Already connected, sent UID payload to ${device.id}");
      } else {
        print("Requesting connection to ${device.id} (${device.name})");
        await _nearby.requestConnection(
          widget.myUid,
          device.id,
          onConnectionInitiated: _onConnectionInitiated,
          onConnectionResult: (id, status) {
            print("Connection result: $id, $status");
            if (status == Status.CONNECTED) {
              // Add to connected endpoints
              connectedEndpoints.add(id);
              // Send payload after connection is established
              SendPayLoad(id);

              // Check if a payload was already received from this device
              if (receivedFriendUid.contains(device.name)) {
                _addFriend(device.name);
                receivedFriendUid.remove(device.name);
              } else {
                sentFriendUid.add(device.name);
              }
            }
          },
          onDisconnected: (id) {
            print("Disconnected from: $id");
            connectedEndpoints.remove(id);
          },
        );
      }
    } catch (e) {
      _showErrorSnackBar("Connection failed: ${e.toString()}");
    }
  }


  Future<void> _addFriend(String friendUid) async {
    try {
      print("Adding friend with UID: $friendUid");
      await AddFriendDirectly().addFriend(widget.myUid, friendUid);
      List<FriendInformation> friends = await GetFriends().getFriends(widget.myUid);
      setState(() {
        Provider.of<UserData>(context, listen: false).updateFriends(friends);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Friend added successfully.')));
    } catch (e) {
      _showErrorSnackBar("Failed to add friend: ${e.toString()}");
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
      body: Padding(
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
              onPressed: isDiscovering ? _stopNearbyServices : _startNearbyServices,
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
                  ? Center(child: Text('No devices found.'))
                  : ListView.builder(
                itemCount: discoveredDevices.length,
                itemBuilder: (context, index) {
                  Device device = discoveredDevices[index];
                  UserInformation? userInfo = cachedUserInfo[device.name];

                  if (userInfo == null) {
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.id),
                      trailing: CircularProgressIndicator(),
                    );
                  } else {
                    bool isSent = sentFriendUid.contains(device.name);
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (!isSent) {
                          _connectToDevice(device);
                        }
                      },
                      child: Container(
                        color: isSent ? Colors.grey[300] : GlobalColor.ItemCol, // Grey out if sent
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                    "https://calendar-files.woody1227.com/user_icon/${userInfo.uicon}",
                                  ),
                                ),
                                SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userInfo.uname,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    Text(
                                      "@${userInfo.uid}",
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                    ),
                                    if (isSent)
                                      Text(
                                        "送信済み",
                                        style: TextStyle(color: Colors.red, fontSize: 15),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
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
