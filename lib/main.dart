import 'dart:convert';
import 'dart:io' as IO;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:krishi/placeholder.dart';
import 'package:krishi/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'device_control_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class IoTDeviceDashboard extends StatefulWidget {
  @override
  _IoTDeviceDashboardState createState() => _IoTDeviceDashboardState();
}
class BottomNavScreen extends StatefulWidget {
  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = [
    IoTDeviceDashboard(),
    DeviceControlScreen(),
    // HistoryScreen(),

    ManageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Show selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: "Menu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
        selectedItemColor: Colors.blue, // Highlight selected tab
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: BottomNavScreen(),
    );
  }
}
class _IoTDeviceDashboardState extends State<IoTDeviceDashboard> {
  late IO.Socket socket;
  String electricityState = "OFF";
  bool isConnected = false;
  final List<Map<String, dynamic>> devices = [
    {"name": "OpenWell", "state": "ON", "remainingTime": 0},
    {"name": "BudliMotor", "state": "ON", "remainingTime": 0},
    {"name": "DhaniMotor", "state": "ON", "remainingTime": 0},
    {"name": "15BighaMotor", "state": "OFF", "remainingTime": 0},
  ];

  List<String> selectedDevices = [];
  int selectedTime = 0; // Time in minutes
  Timer? countdownTimer;
  IOWebSocketChannel? channel;

  @override
  void initState() {
    super.initState();

    _connectWebSocket();
    _fetchInitialData();
  }
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

  void _connectWebSocket() {
    channel = IOWebSocketChannel.connect('ws://localhost:3000/devices/stopwatch');

    channel!.stream.listen((message) {
      Map<String, dynamic> data = _parseJson(message);
      setState(() {
        for (var device in devices) {
          if (data.containsKey(device["name"])) {
            device["remainingTime"] = data[device["name"]];
          }
        }
      });
    });
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      return {
        "OpenWell": 1200,
        "BudliMotor": 300,
        "DhaniMotor": 900,
        "15BighaMotor": 600
      }; // Dummy values for testing
    } catch (e) {
      return {};
    }
  }

  void _startTimer() {
    if (selectedDevices.isEmpty || selectedTime == 0) return;

    for (var device in devices) {
      if (selectedDevices.contains(device["name"])) {
        device["remainingTime"] = selectedTime * 60; // Convert minutes to seconds
      }
    }
    setState(() {});

    // Send start request to backend
    channel!.sink.add("START_TIMER:$selectedTime");

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        for (var device in devices) {
          if (selectedDevices.contains(device["name"]) && device["remainingTime"] > 0) {
            device["remainingTime"]--;
          }
        }
      });

      if (devices.every((device) => device["remainingTime"] <= 0)) {
        timer.cancel();
      }
    });
  }

  void _resetTimer() {
    for (var device in devices) {
      if (selectedDevices.contains(device["name"])) {
        device["remainingTime"] = 0;
      }
    }
    setState(() {});

    // Send reset request to backend
    channel!.sink.add("RESET_TIMER");

    countdownTimer?.cancel();
  }

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hms,
            initialTimerDuration: Duration(minutes: selectedTime),
            onTimerDurationChanged: (Duration newDuration) {
              setState(() {
                selectedTime = newDuration.inMinutes;
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("IoT Controller"),
        backgroundColor: Colors.green,
        actions: [
          // Left Electricity Indicator
          // Right Electricity Indicator
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: Duration(seconds: 1),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: electricityState == "ON" ? Colors.green : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: electricityState == "ON"
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    blurRadius: 6,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(

        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Device Selection Dropdown
            DropdownButtonFormField<String>(
              items: devices.map((device) {
                return DropdownMenuItem<String>(
                  value: device["name"],
                  child: Text(device["name"]),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  if (value != null && !selectedDevices.contains(value)) {
                    selectedDevices.add(value);
                  }
                });
              },
              decoration: InputDecoration(
                labelText: "Select Devices",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            Wrap(
              children: selectedDevices.map((device) {
                return Chip(
                  label: Text(device),
                  onDeleted: () {
                    setState(() {
                      selectedDevices.remove(device);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 10),

            // Timer Selection (Cupertino Picker)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showTimePicker,
                    child: Text(selectedTime > 0
                        ? "Selected Time: $selectedTime min"
                        : "Select Time"),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _startTimer,
                  child: Text("Start Timer"),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Grid of Devices
            Expanded(
              child: GridView.builder(
                itemCount: devices.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: screenWidth / (screenHeight * 0.8),
                ),
                itemBuilder: (context, index) {
                  var device = devices[index];
                  return _buildSpeedometer(device, screenHeight, screenWidth);
                },
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => DeviceControlScreen()),
            //     );
            //   },
            //   child: Text("Manage Devices"),
            // ),
            SizedBox(height: 16),

            // Show Reset Button only if the timer has started
            if (selectedDevices.any((device) =>
            devices.firstWhere((d) => d["name"] == device)["remainingTime"] > 0))
              ElevatedButton(
                onPressed: _resetTimer,
                child: Text("Reset Timer for Selected Devices"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedometer(Map<String, dynamic> device, double screenHeight, double screenWidth) {
    double percentage = (device["remainingTime"] / (selectedTime * 60)).clamp(0.0, 1.0);

    return Container(
      height: screenHeight * 0.35,
      width: screenWidth * 0.45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(device["name"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: screenHeight * 0.15,
                width: screenHeight * 0.15,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[300],
                  color: device["state"] == "ON" ? Colors.green : Colors.red,
                ),
              ),
      Text(
        formatTime(device["remainingTime"]),
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),

            ],
          ),
          SizedBox(height: 10),
          Text("Status: ${device["state"]}", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  String formatTime(int totalSeconds) {
    if (totalSeconds >= 86400) {
      int days = totalSeconds ~/ 86400;
      int hours = (totalSeconds % 86400) ~/ 3600;
      int minutes = (totalSeconds % 3600) ~/ 60;
      return "$days d ${hours}h ${minutes}m";
    } else if (totalSeconds >= 3600) {
      int hours = totalSeconds ~/ 3600;
      int minutes = (totalSeconds % 3600) ~/ 60;
      return "$hours h ${minutes}m";
    } else if (totalSeconds >= 60) {
      int minutes = totalSeconds ~/ 60;
      int seconds = totalSeconds % 60;
      return "$minutes min ${seconds}s";
    } else {
      return "$totalSeconds sec";
    }
  }

}
