import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Example Bluetooth manager implementation
/// This demonstrates how to scan, connect, and interact with Bluetooth devices
class BluetoothManager {
  // Stream subscription for scan results
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  
  // Currently connected device
  BluetoothDevice? _connectedDevice;
  
  // List of discovered devices
  final List<BluetoothDevice> _discoveredDevices = [];
  
  // Getter for discovered devices
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  
  // Getter for connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;
  
  /// Check if Bluetooth is supported on this device
  Future<bool> isBluetoothSupported() async {
    return await FlutterBluePlus.isSupported;
  }
  
  /// Check current Bluetooth adapter state
  Future<BluetoothAdapterState> getBluetoothState() async {
    return await FlutterBluePlus.adapterState.first;
  }
  
  /// Turn on Bluetooth (Android only)
  Future<void> turnOn() async {
    await FlutterBluePlus.turnOn();
  }
  
  /// Start scanning for Bluetooth devices
  /// [timeout] - Duration to scan for (default: 4 seconds)
  /// [filter] - Optional filter for device names or services
  Future<void> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    // Clear previous results
    _discoveredDevices.clear();
    
    // Check if Bluetooth is on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is not turned on');
    }
    
    // Start scanning
    await FlutterBluePlus.startScan(timeout: timeout);
    
    // Listen to scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        // Avoid duplicates
        if (!_discoveredDevices.any((device) => device.remoteId == result.device.remoteId)) {
          _discoveredDevices.add(result.device);
        }
      }
    });
  }
  
  /// Stop scanning for devices
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }
  
  /// Connect to a specific Bluetooth device
  /// [device] - The device to connect to
  /// [timeout] - Connection timeout (default: 15 seconds)
  Future<void> connectToDevice(BluetoothDevice device, {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      // Connect to the device
      await device.connect(timeout: timeout, autoConnect: false);
      _connectedDevice = device;
      
      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
        }
      });
    } catch (e) {
      throw Exception('Failed to connect to device: $e');
    }
  }
  
  /// Disconnect from the current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }
  
  /// Discover services on the connected device
  Future<List<BluetoothService>> discoverServices() async {
    if (_connectedDevice == null) {
      throw Exception('No device connected');
    }
    
    return await _connectedDevice!.discoverServices();
  }
  
  /// Read a characteristic value
  /// [characteristic] - The characteristic to read from
  Future<List<int>> readCharacteristic(BluetoothCharacteristic characteristic) async {
    return await characteristic.read();
  }
  
  /// Write to a characteristic
  /// [characteristic] - The characteristic to write to
  /// [value] - The data to write (list of bytes)
  /// [withoutResponse] - Whether to write without response (default: false)
  Future<void> writeCharacteristic(
    BluetoothCharacteristic characteristic,
    List<int> value, {
    bool withoutResponse = false,
  }) async {
    await characteristic.write(value, withoutResponse: withoutResponse);
  }
  
  /// Subscribe to characteristic notifications
  /// [characteristic] - The characteristic to subscribe to
  /// Returns a stream of the characteristic values
  Stream<List<int>> subscribeToCharacteristic(BluetoothCharacteristic characteristic) async* {
    await characteristic.setNotifyValue(true);
    yield* characteristic.lastValueStream;
  }
  
  /// Clean up resources
  void dispose() {
    stopScan();
    disconnect();
  }
}
