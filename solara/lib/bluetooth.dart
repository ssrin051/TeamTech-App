import 'package:flutter/material.dart';
import 'bluetooth_screen.dart';

class BluetoothButton extends StatelessWidget {
  const BluetoothButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BluetoothScreen()),
        );
      },
      icon: const Icon(Icons.bluetooth),
      label: const Text('Connect Bluetooth'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        foregroundColor: const Color.fromRGBO(255, 187, 210, 1),
      ),
    );
  }
}