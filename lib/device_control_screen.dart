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

    @override
    void initState() {
      super.initState();
      _connectWebSocket();
      _fetchDevices();
    }

    Future<void> _fetchDevices() async {
      try {
        final response = await http.get(
            Uri.parse("https://sutharagriculture.onrender.com/devices/get"));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          print("Fetched Devices: $data"); // Debugging output
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
        print("WebSocket Connected!");
      });

      socket.onDisconnect((_) {
        print("WebSocket Disconnected. Reconnecting in 5s...");
        Future.delayed(Duration(seconds: 5), _connectWebSocket);
      });

      socket.on("stateUpdated", (data) {
        print("Device state update received: $data");
        setState(() {
          int index = devices.indexWhere((device) => device["deviceId"] == data["deviceId"]);
          if (index != -1) {
            devices[index]["state"] = data["state"];
          }
        });
      });

      socket.onError((error) {
        print("WebSocket Error: $error");
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

    @override
    void dispose() {
      socket.disconnect();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("Device Control")),
        body: devices.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(devices[index]["name"]),
                subtitle: Text("State: ${devices[index]["state"]}"),
                trailing: Switch(
                  value: devices[index]["state"] == "ON",
                  onChanged: (value) => _toggleDeviceState(index),
                ),
              ),
            );
          },
        ),
      );
    }
  }
