import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'ble_constants.dart';
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
  BleUiConnectionState _connectionState = BleUiConnectionState.disconnected;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isSubscribing = false;
  List<DiscoveredBleDevice> _devices = <DiscoveredBleDevice>[];
  String _statusMessage = 'Checking Bluetooth...';
  String _lastStatusPayload = 'No status received';
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<DiscoveredBleDevice>>? _devicesSubscription;
  StreamSubscription<BleUiConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _statusSubscription;

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

    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
        _updateStatusMessage();
      });
    });

    _devicesSubscription = _bluetoothService.devicesStream.listen((devices) {
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = devices;
      });
    });

    _connectionSubscription = _bluetoothService.connectionStream.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connectionState = state;
        _isConnecting = state == BleUiConnectionState.connecting;
        _updateStatusMessage();
      });
    });

    _statusSubscription = _bluetoothService.statusStream.listen((bytes) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastStatusPayload = utf8.decode(bytes, allowMalformed: true);
      });
    });

    _adapterState = await _bluetoothService.getBluetoothState();
    _updateStatusMessage();
  }

  void _updateStatusMessage() {
    setState(() {
      if (_isScanning) {
        _statusMessage = 'Scanning for rover...';
        return;
      }
      if (_connectionState == BleUiConnectionState.connecting || _isConnecting) {
        _statusMessage = 'Connecting to rover...';
        return;
      }
      if (_connectionState == BleUiConnectionState.connected) {
        _statusMessage = 'Connected';
        return;
      }

      switch (_adapterState) {
        case BluetoothAdapterState.on:
          _statusMessage = 'Disconnected';
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
      _devices = <DiscoveredBleDevice>[];
      _statusMessage = 'Scanning for rover...';
    });

    try {
      await _bluetoothService.startScan(
        timeout: const Duration(seconds: 6),
        nameFilter: 'solara',
        serviceUuidFilter: kRoverServiceUUID,
      );
      await Future.delayed(const Duration(seconds: 6));
      await _bluetoothService.stopScan();

      setState(() {
        _isScanning = false;
        _statusMessage = 'Found ${_devices.length} device(s)';
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

  Future<void> _connectToDevice(DiscoveredBleDevice device) async {
    try {
      setState(() {
        _isConnecting = true;
        _statusMessage = 'Connecting to ${device.name}...';
      });

      await _bluetoothService.connectToDevice(device);
      await _bluetoothService.subscribeToStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Connected to ${device.name}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
        setState(() {
          _isConnecting = false;
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
          _isConnecting = false;
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

  Future<void> _sendTestCommand() async {
    try {
      await _bluetoothService.sendCommand(utf8.encode('PING'));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Command sent: PING')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command write failed: $e')),
      );
    }
  }

  Future<void> _readStatus() async {
    try {
      final List<int> status = await _bluetoothService.readStatus();
      setState(() {
        _lastStatusPayload = utf8.decode(status, allowMalformed: true);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status read failed: $e')),
      );
    }
  }

  Future<void> _subscribeToStatus() async {
    setState(() {
      _isSubscribing = true;
    });
    try {
      await _bluetoothService.subscribeToStatus();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscribe failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubscribing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _devicesSubscription?.cancel();
    _connectionSubscription?.cancel();
    _statusSubscription?.cancel();
    unawaited(_bluetoothService.dispose());
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
          if (_connectionState == BleUiConnectionState.connected)
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
                      ? (_connectionState == BleUiConnectionState.connected
                            ? Colors.green.shade50
                            : Colors.orange.shade50)
                      : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _connectionState == BleUiConnectionState.connected
                    ? Colors.green
                    : (_adapterState == BluetoothAdapterState.on
                        ? Colors.orange
                        : Colors.red),
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
                                  ? (_connectionState == BleUiConnectionState.connected
                                      ? Colors.green
                                      : Colors.orange)
                                  : Colors.red,
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
                            'Status: ${_connectionState.name} | Adapter: ${_adapterState.toString().split('.').last}',
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
                    : (_connectionState == BleUiConnectionState.connected
                    ? null
                        : _startScan),
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
            child: _devices.isEmpty
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
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isConnected = _bluetoothService.connectedDevice?.id == device.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                            color: isConnected ? Colors.blue : Colors.grey,
                          ),
                          title: Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(device.id),
                          trailing: isConnected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: isConnected || _isConnecting ? null : () => _connectToDevice(device),
                        ),
                      );
                    },
                  ),
          ),
          if (_connectionState == BleUiConnectionState.connected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Last Status: $_lastStatusPayload',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _sendTestCommand,
                          child: const Text('Send Test Command'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _readStatus,
                          child: const Text('Read Status'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubscribing ? null : _subscribeToStatus,
                      icon: _isSubscribing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active),
                      label: const Text('Subscribe to Status Notifications'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
