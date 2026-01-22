import 'package:flutter/material.dart';

class ControlButtons extends StatefulWidget {
  const ControlButtons({super.key});

  @override
  State<ControlButtons> createState() => _ControlButtonsState();
}

class _ControlButtonsState extends State<ControlButtons> {
  String selectedMode = 'Auto';
  double brightness = 50.0;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selection Section
        const Text(
          'Mode Selection',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeButton('Auto'),
            _buildModeButton('Manual'),
            _buildModeButton('Schedule'),
          ],
        ),
                
        const SizedBox(height: 30),
        
        // Quick Action Buttons
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: () {
            // Status button action
          },
          icon: const Icon(Icons.info_outline),
          label: const Text('View Status'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Color.fromRGBO(255, 187, 210, 1),
            foregroundColor: Colors.white,
          ),
        ),
        
        const SizedBox(height: 10),
        
        ElevatedButton.icon(
          onPressed: () {
            // Settings button action
          },
          icon: const Icon(Icons.settings),
          label: const Text('Settings'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Color.fromRGBO(255, 187, 210, 1),
            foregroundColor: Colors.white,
          ),
        ),
        
        const SizedBox(height: 10),
        
        ElevatedButton.icon(
          onPressed: () {
            // Timer button action
          },
          icon: const Icon(Icons.timer),
          label: const Text('Set Timer'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Color.fromRGBO(255, 187, 210, 1),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildModeButton(String mode) {
    bool isSelected = selectedMode == mode;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedMode = mode;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Color.fromRGBO(255, 187, 210, 1) : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(mode),
    );
  }
}