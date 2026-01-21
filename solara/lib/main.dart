import 'package:flutter/material.dart';
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'SOLARA - TEAM TECH',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(225, 122, 156, 1),
                ),
              ),
              const SizedBox(height: 30),
              const OnOffToggle(),
              const SizedBox(height: 30),
              const BluetoothButton(),
              const SizedBox(height: 30),
              const ControlButtons(),
            ],
          ),
        ),
      ),
    );
  }
}