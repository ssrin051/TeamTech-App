import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  Stream<List<ScanResult>> scanForDevices() {
    flutterBlue.startScan(timeout: Duration(seconds: 5));
    return flutterBlue.scanResults;
  }

  Future<void> stopScan() async {
    await flutterBlue.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
  }
}
