import 'dart:async';

import 'package:ble_device_provider/state_stream.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';

class BleScanner extends StatefulStream<BleScanState> {
  StreamSubscription? _subscription;
  final _devices = <DiscoveredDevice>[];
  final FlutterReactiveBle _ble;

  BleScanner(this._ble);

  @override
  BleScanState get state => BleScanState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
      );

  void startScan(List<Uuid> serviceIds) {
    _devices.clear();
    _subscription?.cancel();
    _subscription = _ble.scanForDevices(withServices: serviceIds).listen((device) {
      final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        _devices[knownDeviceIndex] = device;
      } else {
        _devices.add(device);
      }
      addStateToStream(state);
    }, onError: (Object e) {});
    addStateToStream(state);
  }

  Future<void> stopScan() async {
    await _subscription?.cancel();
    _subscription = null;
    addStateToStream(state);
  }
}

@immutable
class BleScanState {
  const BleScanState({
    required this.discoveredDevices,
    required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
}
