import 'package:flutter/material.dart';

class AttendanceListScreen extends StatelessWidget {
  const AttendanceListScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance List')),
      body: const Center(child: Text('Attendance List Screen')),
    );
  }
}
