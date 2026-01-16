import 'package:flutter/material.dart';
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
      home: Scaffold(
        body: Stack(
          children:[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logos/solara_logo.png',
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  const OnOffToggle(),
                ],
              ),
            ),

            Positioned(
              top: 40,    // Distance from the top
              right: 20,  // Distance from the right
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logos/gcap_logo.png', height: 40),
                  const SizedBox(height: 15),
                  Image.asset('assets/logos/swe_logo.png', height: 40),
                  const SizedBox(height: 15),
                  Image.asset('assets/logos/tt_logo.png', height: 40),
                ],
              ),
            ),
          ],
        ),  
      ),
    );
  }
}
