import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class StatusScreen extends StatefulWidget {
  final FlutterReactiveBle _ble;
  const StatusScreen(this._ble, {super.key});

  @override
  State<StatusScreen> createState() => StatusScreenState();
}

class StatusScreenState extends State<StatusScreen> {
  String _determineText(BleStatus status) {
    switch (status) {
      case BleStatus.unsupported:
        return tr('ThisDeviceDoesNotSupportBluetooth');
      case BleStatus.unauthorized:
        return tr('AuthorizeApplicationToUseBluetoothAndLocation');
      case BleStatus.poweredOff:
        return tr('BluetoothIsDisabledTurnItOn');
      case BleStatus.locationServicesDisabled:
        return tr('LocationServicesAreDisabledEnableThem');
      case BleStatus.ready:
        return tr('BluetoothIsUpAndRunning');
      default:
        return tr('WaitingToFetchBluetoothStatus', args: ['$status']);
    }
  }

  IconData _determineIcon(BleStatus status) {
    switch (status) {
      case BleStatus.unsupported:
        return Icons.bluetooth_disabled_rounded;
      case BleStatus.unauthorized:
        return Icons.person_off_rounded;
      case BleStatus.poweredOff:
        return Icons.bluetooth_disabled_rounded;
      case BleStatus.locationServicesDisabled:
        return Icons.location_off_rounded;
      case BleStatus.ready:
        return Icons.bluetooth_rounded;
      default:
        return Icons.autorenew_rounded;
    }
  }

  void _evaluateBleStatus(BleStatus status) {
    setState(() {
      if (status == BleStatus.ready) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget._ble.statusStream.listen(_evaluateBleStatus);
    () async {
      if (Platform.isAndroid) {
        await Permission.location.request();
      }
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothAdvertise.request();
      await Permission.bluetoothConnect.request();
    }.call();
    _evaluateBleStatus(widget._ble.status);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            minimum: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _determineText(widget._ble.status),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30.0,
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  _determineIcon(widget._ble.status),
                  size: 100,
                ),
              ],
            ),
          ),
        ),
      );
}
