import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothTestScreen extends StatefulWidget {
  @override
  State<BluetoothTestScreen> createState() => _BluetoothTestScreenState();
}

class _BluetoothTestScreenState extends State<BluetoothTestScreen> {
  final bluetooth = BluetoothService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Test')),
      body: StreamBuilder<List<ScanResult>>(
        stream: bluetooth.scanForDevices(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final devices = snapshot.data!;
          return ListView(
            children: devices.map((d) {
              return ListTile(
                leading: Icon(Icons.bluetooth),
                title: Text(d.device.name.isEmpty ? "Unknown device" : d.device.name),
                subtitle: Text(d.device.id.toString()),
                onTap: () async {
                  await bluetooth.connectToDevice(d.device);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

