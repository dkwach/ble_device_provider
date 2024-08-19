import 'dart:async';

import 'package:ble_device_provider/state_stream.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleConnector extends StatefulStream<BleConnectionState> {
  BleConnector(this._ble, {required this.deviceId});

  final String deviceId;
  BleConnectionState _state = BleConnectionState.disconnected;
  late StreamSubscription<ConnectionStateUpdate> _connection;
  final FlutterReactiveBle _ble;

  @override
  BleConnectionState get state => _state;

  void _updateState(ConnectionStateUpdate update) {
    final newState = update.connectionState == DeviceConnectionState.connected
        ? BleConnectionState.connected
        : BleConnectionState.disconnected;
    _notifyIfChanged(newState);
  }

  void _notifyIfChanged(BleConnectionState newState) {
    if (newState != _state) {
      _state = newState;
      addStateToStream(state);
    }
  }

  Future<void> findAndConnect(Uuid uuid) async {
    _connection = _ble
        .connectToAdvertisingDevice(id: deviceId, withServices: [uuid], prescanDuration: const Duration(seconds: 20))
        .listen(
          _updateState,
          onError: (Object e) {},
        );
  }

  Future<void> connect() async {
    _connection = _ble.connectToDevice(id: deviceId).listen(
          _updateState,
          onError: (Object e) {},
        );
  }

  Future<void> disconnect() async {
    try {
      await _connection.cancel();
    } catch (_) {
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated
      _notifyIfChanged(BleConnectionState.disconnected);
    }
  }
}

enum BleConnectionState {
  connected,
  disconnected,
}
