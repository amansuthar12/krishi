import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT Controller',
      theme: ThemeData.dark(),
      home: IoTControlScreen(),
    );
  }
}

class IoTControlScreen extends StatefulWidget {
  @override
  _IoTControlScreenState createState() => _IoTControlScreenState();
}

class _IoTControlScreenState extends State<IoTControlScreen> {
  late IO.Socket socket;
  String electricityState = "OFF";
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchInitialData();
  }

  // 🔹 Fetch initial electricity state from REST API
  Future<void> _fetchInitialData() async {
    try {
      final response = await http.get(
          Uri.parse("https://sutharagriculture.onrender.com/electricity/get"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          electricityState = data["state"];
        });
      }
    } catch (error) {
      print("Error fetching initial electricity state: $error");
    }
  }

  // 🔹 Connect to WebSocket server using Socket.IO
  void _connectWebSocket() {
    socket = IO.io("https://sutharagriculture.onrender.com", <String, dynamic>{
      "transports": ["websocket"],  // Force WebSocket connection
      "autoConnect": false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("WebSocket Connected!");
      setState(() {
        isConnected = true;
      });
    });

    socket.onDisconnect((_) {
      print("WebSocket Disconnected. Reconnecting in 5s...");
      setState(() {
        isConnected = false;
      });
      Future.delayed(Duration(seconds: 5), _connectWebSocket);
    });

    socket.on("electricityStateUpdated", (data) {
      setState(() {
        electricityState = data["state"];
      });
      print("Updated UI with new electricity state: $electricityState");
    });

    socket.onError((error) {
      print("WebSocket Error: $error");
      setState(() {
        isConnected = false;
      });
      Future.delayed(Duration(seconds: 5), _connectWebSocket);
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
      appBar: AppBar(
        title: Text("IoT Controller"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔹 Electricity Status Indicator
            Text(
              "Electricity Status",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            AnimatedContainer(
              duration: Duration(seconds: 1),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: electricityState == "ON" ? Colors.green : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: electricityState == "ON"
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              electricityState == "ON" ? "Active" : "Inactive",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),

            SizedBox(height: 40),

            // 🔹 Connection Status Indicator
            Text(
              isConnected ? "Connected ✅" : "Disconnected ❌",
              style: TextStyle(
                  fontSize: 16,
                  color: isConnected ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
