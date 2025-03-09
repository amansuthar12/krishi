import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Home Screen", style: TextStyle(fontSize: 24)),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("History Screen", style: TextStyle(fontSize: 24)),
    );
  }
}

class ManageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings & Management"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // User Profile Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text("John Doe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text("johndoe@example.com"),
              trailing: Icon(Icons.edit, color: Colors.blue),
              onTap: () {
                // Navigate to profile edit screen
              },
            ),
          ),
          SizedBox(height: 20),

          // App Settings Section
          Text("App Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: "Notifications",
            subtitle: "Manage push notifications",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: "Dark Mode",
            subtitle: "Enable or disable dark mode",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: "Privacy & Security",
            subtitle: "Manage app security settings",
            onTap: () {},
          ),
          SizedBox(height: 20),

          // Device Management Section
          Text("Device Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _buildSettingsTile(
            icon: Icons.settings_remote,
            title: "Manage Devices",
            subtitle: "Control connected IoT devices",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.timer,
            title: "Timer Settings",
            subtitle: "Configure timer for devices",
            onTap: () {},
          ),
          SizedBox(height: 20),

          // Support & About
          Text("Support & About", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _buildSettingsTile(
            icon: Icons.info,
            title: "About App",
            subtitle: "Version 1.0.0",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.help,
            title: "Help & Support",
            subtitle: "Contact support team",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Sign out from the app",
            onTap: () {
              // Logout logic here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.green),
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

