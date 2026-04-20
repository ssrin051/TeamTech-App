import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_constants.dart';

enum BleUiConnectionState {
  disconnected,
  connecting,
  connected,
}

class DiscoveredBleDevice {
  const DiscoveredBleDevice({
    required this.id,
    required this.name,
    this.device,
    this.isMock = false,
  });

  final String id;
  final String name;
  final BluetoothDevice? device;
  final bool isMock;
}

class BluetoothManager {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _statusNotificationSubscription;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _statusCharacteristic;
  bool _isMockConnected = false;
  List<int> _mockStatus = utf8.encode('MOCK_DISCONNECTED');

  final List<DiscoveredBleDevice> _discoveredDevices = [];
  final StreamController<List<DiscoveredBleDevice>> _devicesController =
      StreamController<List<DiscoveredBleDevice>>.broadcast();
  final StreamController<BleUiConnectionState> _connectionController =
      StreamController<BleUiConnectionState>.broadcast();
  final StreamController<List<int>> _statusController =
      StreamController<List<int>>.broadcast();

  List<DiscoveredBleDevice> get discoveredDevices =>
      List<DiscoveredBleDevice>.unmodifiable(_discoveredDevices);
  DiscoveredBleDevice? get connectedDevice {
    if (_isMockConnected) {
      return const DiscoveredBleDevice(
        id: 'mock-rover-id',
        name: kMockDeviceName,
        isMock: true,
      );
    }

    final device = _connectedDevice;
    if (device == null) {
      return null;
    }

    return DiscoveredBleDevice(
      id: device.remoteId.toString(),
      name: device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
      device: device,
    );
  }

  Stream<List<DiscoveredBleDevice>> get devicesStream => _devicesController.stream;
  Stream<BleUiConnectionState> get connectionStream => _connectionController.stream;
  Stream<List<int>> get statusStream => _statusController.stream;

  Future<bool> isBluetoothSupported() async => FlutterBluePlus.isSupported;

  Future<BluetoothAdapterState> getBluetoothState() async =>
      FlutterBluePlus.adapterState.first;

  Future<void> turnOn() async {
    await FlutterBluePlus.turnOn();
  }

  Future<void> ensureRuntimePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final List<Permission> permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    if (Platform.isIOS) {
      permissions.add(Permission.bluetooth);
    }

    for (final Permission permission in permissions) {
      final PermissionStatus status = await permission.request();
      if (!status.isGranted) {
        throw Exception('Missing runtime permission: $permission');
      }
    }
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 6),
    String? nameFilter,
    String? serviceUuidFilter,
  }) async {
    await stopScan();
    _discoveredDevices.clear();
    _emitDiscoveredDevices();

    if (kUseMockBLE) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      _discoveredDevices.add(
        const DiscoveredBleDevice(
          id: 'mock-rover-id',
          name: kMockDeviceName,
          isMock: true,
        ),
      );
      _emitDiscoveredDevices();
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is not turned on');
    }

    await ensureRuntimePermissions();

    final Guid targetService = Guid(serviceUuidFilter ?? kRoverServiceUUID);
    final String normalizedName = (nameFilter ?? 'rover').toLowerCase();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final ScanResult result in results) {
        final BluetoothDevice device = result.device;
        final String deviceName = device.platformName;
        final bool matchesName = deviceName.toLowerCase().contains(normalizedName);
        final bool matchesService = result.advertisementData.serviceUuids.any(
          (service) => service.str.toLowerCase() == targetService.str.toLowerCase(),
        );

        if (!matchesName && !matchesService) {
          continue;
        }

        final String id = device.remoteId.toString();
        final bool alreadyAdded = _discoveredDevices.any((d) => d.id == id);
        if (alreadyAdded) {
          continue;
        }

        _discoveredDevices.add(
          DiscoveredBleDevice(
            id: id,
            name: deviceName.isNotEmpty ? deviceName : 'Unknown Device',
            device: device,
          ),
        );
      }
      _emitDiscoveredDevices();
    });

    await FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: <Guid>[targetService],
    );
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(
    DiscoveredBleDevice target, {
    Duration timeout = const Duration(seconds: 12),
    int retries = 2,
  }) async {
    _connectionController.add(BleUiConnectionState.connecting);
    await stopScan();

    if (target.isMock) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      _isMockConnected = true;
      _mockStatus = utf8.encode('MOCK_CONNECTED');
      _connectionController.add(BleUiConnectionState.connected);
      _statusController.add(_mockStatus);
      return;
    }

    final BluetoothDevice? device = target.device;
    if (device == null) {
      _connectionController.add(BleUiConnectionState.disconnected);
      throw Exception('Selected device is unavailable.');
    }

    await ensureRuntimePermissions();

    Object? lastError;
    for (int attempt = 1; attempt <= retries + 1; attempt++) {
      try {
        await device.connect(timeout: timeout, autoConnect: false);
        _connectedDevice = device;
        _connectionController.add(BleUiConnectionState.connected);

        await _connectionStateSubscription?.cancel();
        _connectionStateSubscription = device.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected) {
            _connectedDevice = null;
            _commandCharacteristic = null;
            _statusCharacteristic = null;
            _connectionController.add(BleUiConnectionState.disconnected);
          }
        });

        await discoverAndBindCharacteristics();
        return;
      } catch (error) {
        lastError = error;
        if (attempt <= retries) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }

    _connectionController.add(BleUiConnectionState.disconnected);
    throw Exception('Failed to connect after retries: $lastError');
  }

  Future<void> discoverAndBindCharacteristics() async {
    final BluetoothDevice? device = _connectedDevice;
    if (device == null) {
      throw Exception('No device connected');
    }

    final List<BluetoothService> services = await device.discoverServices();
    for (final BluetoothService service in services) {
      print('Discovered service: ${service.uuid}');
      for (final BluetoothCharacteristic characteristic in service.characteristics) {
        print(
          '  characteristic: ${characteristic.uuid} '
          '(read=${characteristic.properties.read}, '
          'write=${characteristic.properties.write || characteristic.properties.writeWithoutResponse}, '
          'notify=${characteristic.properties.notify})',
        );
      }
    }

    final Guid roverServiceGuid = Guid(kRoverServiceUUID);
    final Guid commandGuid = Guid(kCommandCharacteristicUUID);
    final Guid statusGuid = Guid(kStatusCharacteristicUUID);

    final BluetoothService? roverService = services.cast<BluetoothService?>().firstWhere(
      (service) => service?.uuid == roverServiceGuid,
      orElse: () => null,
    );
    if (roverService == null) {
      throw Exception('Rover service not found: $kRoverServiceUUID');
    }

    _commandCharacteristic = roverService.characteristics.cast<BluetoothCharacteristic?>().firstWhere(
      (c) => c?.uuid == commandGuid,
      orElse: () => null,
    );
    _statusCharacteristic = roverService.characteristics.cast<BluetoothCharacteristic?>().firstWhere(
      (c) => c?.uuid == statusGuid,
      orElse: () => null,
    );

    if (_commandCharacteristic == null) {
      throw Exception('Command characteristic not found: $kCommandCharacteristicUUID');
    }
    if (_statusCharacteristic == null) {
      throw Exception('Status characteristic not found: $kStatusCharacteristicUUID');
    }
  }

  Future<void> sendCommand(List<int> value) async {
    if (_isMockConnected) {
      _mockStatus = utf8.encode('MOCK_CMD:${value.join(",")}');
      _statusController.add(_mockStatus);
      return;
    }

    final BluetoothCharacteristic? command = _commandCharacteristic;
    if (command == null) {
      throw Exception('Command characteristic unavailable.');
    }
    if (!command.properties.write && !command.properties.writeWithoutResponse) {
      throw Exception('Command characteristic is not writable.');
    }

    await command.write(
      value,
      withoutResponse: command.properties.writeWithoutResponse,
    );
  }

  Future<List<int>> readStatus() async {
    if (_isMockConnected) {
      return _mockStatus;
    }

    final BluetoothCharacteristic? status = _statusCharacteristic;
    if (status == null) {
      throw Exception('Status characteristic unavailable.');
    }
    if (!status.properties.read) {
      throw Exception('Status characteristic is not readable.');
    }

    return status.read();
  }

  Future<void> subscribeToStatus() async {
    if (_isMockConnected) {
      _statusNotificationSubscription?.cancel();
      _statusNotificationSubscription =
          Stream<List<int>>.periodic(const Duration(seconds: 2), (count) {
        return utf8.encode('MOCK_NOTIFY_$count');
      }).listen(_statusController.add);
      return;
    }

    final BluetoothCharacteristic? status = _statusCharacteristic;
    if (status == null) {
      throw Exception('Status characteristic unavailable.');
    }
    if (!status.properties.notify) {
      throw Exception('Status characteristic does not support notifications.');
    }

    await status.setNotifyValue(true);
    await _statusNotificationSubscription?.cancel();
    _statusNotificationSubscription = status.lastValueStream.listen(_statusController.add);
  }

  Future<void> disconnect() async {
    await _statusNotificationSubscription?.cancel();
    _statusNotificationSubscription = null;

    if (_isMockConnected) {
      _isMockConnected = false;
      _mockStatus = utf8.encode('MOCK_DISCONNECTED');
      _connectionController.add(BleUiConnectionState.disconnected);
      return;
    }

    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    _commandCharacteristic = null;
    _statusCharacteristic = null;
    _connectionController.add(BleUiConnectionState.disconnected);
  }

  void _emitDiscoveredDevices() {
    _devicesController.add(List<DiscoveredBleDevice>.unmodifiable(_discoveredDevices));
  }

  Future<void> dispose() async {
    await stopScan();
    await disconnect();
    await _connectionStateSubscription?.cancel();
    await _devicesController.close();
    await _connectionController.close();
    await _statusController.close();
  }
}
