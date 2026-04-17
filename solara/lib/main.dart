import 'package:flutter/material.dart';
import 'bluetooth_screen.dart';
import 'on_off.dart';
import 'bluetooth.dart';
import 'control_buttons.dart';

void main() {
  runApp(const SolaraApp());
}

class SolaraApp extends StatelessWidget {
  const SolaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOLARA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content with scroll
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo section
                  Image.asset(
                    'assets/logos/solara_logo.png',
                    height: 150,
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 30),
                  // On/Off Toggle
                  const OnOffToggle(),
                  const SizedBox(height: 30),
                  // Bluetooth Button with Navigation
                  BluetoothButtonWithNavigation(),
                  const SizedBox(height: 30),
                  // Leash Distance Slider
                  const MyToggleDemo(),
                  const SizedBox(height: 30),
                  // Control Buttons
                  const ControlButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Top-right logos
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logos/gcap_logo.png', height: 40),
                const SizedBox(width: 15),
                Image.asset('assets/logos/swe_logo.png', height: 40),
                const SizedBox(width: 15),
                Image.asset('assets/logos/tt_logo.png', height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Bluetooth Button with Navigation to BluetoothScreen
class BluetoothButtonWithNavigation extends StatelessWidget {
  const BluetoothButtonWithNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BluetoothScreen()),
        );
      },
      child: const BluetoothButton(),
    );
  }
}

// Leash Distance Slider Widget
class MyToggleDemo extends StatefulWidget {
  const MyToggleDemo({super.key});

  @override
  State<MyToggleDemo> createState() => _MyToggleDemoState();
}

class _MyToggleDemoState extends State<MyToggleDemo> {
  double _leashDistance = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leash Distance (ft)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(225, 122, 156, 1),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _leashDistance,
                  min: 0,
                  max: 5,
                  divisions: 100,
                  label: _leashDistance.round().toString(),
                  activeColor: const Color.fromRGBO(225, 122, 156, 1),
                  onChanged: (double value) {
                    setState(() {
                      _leashDistance = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '${_leashDistance.round()}',
                  textAlign: TextAlign.center, 
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ), 
        ],
      ),
    );
  }
}