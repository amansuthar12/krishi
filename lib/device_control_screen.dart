import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class DeviceControlScreen extends StatefulWidget {
  @override
  _DeviceControlScreenState createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late IO.Socket socket;
  List<Map<String, dynamic>> devices = [];
  Timer? timer;
  int selectedTime = 60; // Default time for speedometer calculation

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchDevices();
    _startTimer();
  }

  Future<void> _fetchDevices() async {
    try {
      final response = await http.get(Uri.parse("https://sutharagriculture.onrender.com/devices/get"));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("Fetched Devices: $data");
        setState(() {
          devices = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print("Failed to fetch devices. Status: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching devices: $error");
    }
  }

  void _connectWebSocket() {
    socket = IO.io("https://sutharagriculture.onrender.com", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("✅ WebSocket Connected!");
    });

    socket.onDisconnect((_) {
      print("❌ WebSocket Disconnected. Reconnecting in 5s...");
      Future.delayed(Duration(seconds: 5), _connectWebSocket);
    });

    socket.on("stateUpdated", (data) {
      print("📢 Device state update received: $data");
      setState(() {
        int index = devices.indexWhere((device) => device["deviceId"] == data["deviceId"]);
        if (index != -1) {
          devices[index]["state"] = data["state"];
          devices[index]["totalOnTime"] = data["totalOnTime"];
        }
      });
    });

    socket.onError((error) {
      print("⚠️ WebSocket Error: $error");
      Future.delayed(Duration(seconds: 5), _connectWebSocket);
    });
  }

  void _toggleDeviceState(int index) {
    String newState = devices[index]["state"] == "ON" ? "OFF" : "ON";
    socket.emit("updateState", {
      "deviceId": devices[index]["deviceId"],
      "state": newState,
    });
  }

  Future<void> _resetDeviceTimer(int index) async {
    try {
      final response = await http.post(
        Uri.parse("https://sutharagriculture.onrender.com/resetTimer/new"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "deviceId": devices[index]["deviceId"],
          "totaltime": devices[index]["totalOnTime"],
        }),
      );

      if (response.statusCode == 200) {
        socket.emit("resetTimer", {"deviceId": devices[index]["deviceId"]});
        print("Reset request sent for device: ${devices[index]["deviceId"]}");

        await _fetchDevices(); // Fetch updated data after reset
      } else {
        print("Failed to reset timer");
      }
    } catch (error) {
      print("Error resetting timer: $error");
    }
  }
  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        for (var device in devices) {
          if (device["state"] == "ON") {
            device["totalOnTime"] += 1;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text("Device Control")),
      body: devices.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two columns in the grid
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
            childAspectRatio: screenWidth / (screenHeight * 0.8),
        ),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return _buildSpeedometer(devices[index], screenHeight, screenWidth);
        },
      ),
    );
  }

  Widget _buildSpeedometer(Map<String, dynamic> device, double screenHeight, double screenWidth) {
    double percentage = (device["totalOnTime"] / (selectedTime * 60)).clamp(0.0, 1.0);

    return Container(
      height: screenHeight * 0.7, // Increased height
      width: screenWidth * 0.5,  // Increased width
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 1, // Allocates flexible space
            child: Text(
              device["name"],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 3, // Allocates more space for the speedometer
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: screenHeight * 0.12,
                  width: screenHeight * 0.12,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[300],
                    color: device["state"] == "ON" ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  formatTime(device["totalOnTime"]),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 1, // Allocates space for status text
            child: Text(
              "Status: ${device["state"]}",
              style: TextStyle(fontSize: 16, color: device["state"] == "ON" ? Colors.green : Colors.red),
            ),
          ),

          Expanded(
            flex: 2, // Allocates space for buttons
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: device["state"] == "ON",
                  onChanged: (value) => _toggleDeviceState(devices.indexOf(device)),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.timer_off, color: Colors.orange),
                  onPressed: () => _resetDeviceTimer(devices.indexOf(device)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
