import 'package:flutter/material.dart';
import 'bluetooth_screen.dart';
import 'on_off.dart';

void main() {
  runApp(const MyToggleDemo());
}

class MyToggleDemo extends StatelessWidget {
  const MyToggleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOLARA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BluetoothScreen(),
    );
  }
}
