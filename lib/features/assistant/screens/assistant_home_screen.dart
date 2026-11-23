import 'package:flutter/material.dart';

class AssistantHomeScreen extends StatelessWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant Home')),
      body: const Center(child: Text('Assistant Home Screen')),
    );
  }
}
