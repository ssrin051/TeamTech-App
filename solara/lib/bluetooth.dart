import 'package:flutter/material.dart';
import 'bluetooth_screen.dart';

class BluetoothButton extends StatelessWidget {
  const BluetoothButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        print('Navigating to Bluetooth Screen'); // Debug print
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BluetoothScreen()),
        ).then((value) {
          print('Returned from Bluetooth Screen'); // Debug print
        });
      },
      icon: const Icon(Icons.bluetooth),
      label: const Text('Connect Bluetooth'),
      style: ElevatedButton.styleFrom(
<<<<<<< HEAD
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        foregroundColor: const Color.fromRGBO(255, 187, 210, 1),
=======
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        foregroundColor: Color.fromRGBO(255, 187, 210, 1),
>>>>>>> dc71e14471ed4ef52cb6b430729769999c9c4773
      ),
    );
  }
}