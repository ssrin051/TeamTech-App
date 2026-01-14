import 'package:flutter/material.dart';
import 'on_off.dart';

void main() {
  runApp(const MyToggleDemo());
}

class MyToggleDemo extends StatelessWidget {
  const MyToggleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: OnOffToggle(),
        ),
      ),
    );
  }
}
