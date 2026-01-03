import 'package:flutter/material.dart';

class OnOffToggle extends StatefulWidget {
  const OnOffToggle({super.key});

  @override
  State<OnOffToggle> createState() => _OnOffToggleState();
}

class _OnOffToggleState extends State<OnOffToggle> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isOn = !isOn;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 180,  // longer width
        height: 60,  // same height
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isOn ? Colors.pink : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            // Text in the center
            Align(
              alignment: Alignment.center,
              child: Text(
                isOn ? 'ON' : 'OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            // Moving circle
            Align(
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 60,  // bigger circle for better proportion
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
