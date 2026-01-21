import 'package:flutter/material.dart';

class BluetoothButton extends StatelessWidget {
  const BluetoothButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Add your Bluetooth connection logic here
        print('Bluetooth button pressed');
      },
      icon: Icon(Icons.bluetooth),
      label: Text('Connect Bluetooth'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        foregroundColor: Color.fromRGBO(255, 187, 210, 1),
      ),
    );
  }
}