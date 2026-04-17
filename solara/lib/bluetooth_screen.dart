import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bluetooth_service.dart';

/// Bluetooth Device List Screen
/// Demonstrates how to scan for and connect to Bluetooth devices
class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final BluetoothManager _bluetoothService = BluetoothManager();
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  bool _isScanning = false;
  String _statusMessage = 'Checking Bluetooth...';
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    // Check if Bluetooth is supported
    bool isSupported = await _bluetoothService.isBluetoothSupported();
    if (!isSupported) {
      setState(() {
        _statusMessage = 'Bluetooth is not supported on this device';
      });
      return;
    }

    // Monitor Bluetooth adapter state
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
        _updateStatusMessage();
      });
    });

    // Get initial state
    _adapterState = await _bluetoothService.getBluetoothState();
    _updateStatusMessage();
  }

  void _updateStatusMessage() {
    setState(() {
      switch (_adapterState) {
        case BluetoothAdapterState.on:
          _statusMessage = 'Bluetooth is on. Ready to scan.';
          break;
        case BluetoothAdapterState.off:
          _statusMessage = 'Bluetooth is off. Please turn it on.';
          break;
        case BluetoothAdapterState.turningOn:
          _statusMessage = 'Bluetooth is turning on...';
          break;
        case BluetoothAdapterState.turningOff:
          _statusMessage = 'Bluetooth is turning off...';
          break;
        case BluetoothAdapterState.unauthorized:
          _statusMessage = 'Bluetooth permission denied.';
          break;
        default:
          _statusMessage = 'Unknown Bluetooth state.';
      }
    });
  }

  Future<void> _turnOnBluetooth() async {
    try {
      await _bluetoothService.turnOn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error turning on Bluetooth: $e')),
        );
      }
    }
  }

  Future<void> _startScan() async {
    if (_adapterState != BluetoothAdapterState.on) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn on Bluetooth first')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for devices...';
    });

    try {
      await _bluetoothService.startScan(timeout: const Duration(seconds: 4));
      await Future.delayed(const Duration(seconds: 4));
      await _bluetoothService.stopScan();
      
      setState(() {
        _isScanning = false;
        _statusMessage = 'Found ${_bluetoothService.discoveredDevices.length} device(s)';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error scanning: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _statusMessage = 'Connecting to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}...';
      });

      await _bluetoothService.connectToDevice(device);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _statusMessage = 'Connected to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
        setState(() {
          _statusMessage = 'Connection failed: $e';
        });
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await _bluetoothService.disconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected')),
        );
        setState(() {
          _statusMessage = 'Disconnected';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error disconnecting: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Explicitly navigate back to HomePage
          },
        ),
        title: const Text('SOLARA Bluetooth'),
        actions: [
          if (_bluetoothService.connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: _disconnect,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _adapterState == BluetoothAdapterState.on
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _adapterState == BluetoothAdapterState.on
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Bluetooth Icon
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: SvgPicture.asset(
                        'assets/icons/bluetooth.svg',
                        colorFilter: ColorFilter.mode(
                          _adapterState == BluetoothAdapterState.on
                              ? Colors.green
                              : Colors.orange,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'State: ${_adapterState.toString().split('.').last}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_adapterState == BluetoothAdapterState.off) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _turnOnBluetooth,
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('Turn On Bluetooth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Scan Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning || _adapterState != BluetoothAdapterState.on
                    ? null
                    : _startScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Device List
          Expanded(
            child: _bluetoothService.discoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Scanning for devices...'
                              : 'No devices found.\nTap "Scan for Devices" to search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _bluetoothService.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = _bluetoothService.discoveredDevices[index];
                      final isConnected = _bluetoothService.connectedDevice?.remoteId == device.remoteId;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                            color: isConnected ? Colors.blue : Colors.grey,
                          ),
                          title: Text(
                            device.platformName.isNotEmpty
                                ? device.platformName
                                : 'Unknown Device',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: isConnected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: isConnected ? null : () => _connectToDevice(device),
                        ),
                      ); 
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
