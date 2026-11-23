import 'package:flutter/material.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Offline Scans')),
      body: const Center(child: Text('Sync Screen')),
    );
  }
}
