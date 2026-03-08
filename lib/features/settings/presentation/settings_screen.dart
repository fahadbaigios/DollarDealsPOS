import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('App configuration and backup'),
          ],
        ),
      ),
    );
  }
}
