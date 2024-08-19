import 'dart:async';

import 'package:ble_device_provider/ble_scanner.dart';
import 'package:ble_device_provider/status_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ScannerScreen extends StatefulWidget {
  final FlutterReactiveBle _ble;
  final void Function(DiscoveredDevice device, BuildContext context) onDeviceSelected;
  final Widget? settingsWidget;

  final Uuid scanUuid;
  const ScannerScreen(this._ble, this.scanUuid, this.onDeviceSelected, this.settingsWidget, {super.key});

  @override
  State<ScannerScreen> createState() => ScannerScreenState();
}

class ScannerScreenState extends State<ScannerScreen> {
  Timer? scanTimer;
  late BleScanner bleScanner;

  void _evaluateBleStatus(BleStatus status) {
    setState(() {
      if (status == BleStatus.ready) {
        _startScan();
      } else if (status != BleStatus.unknown) {
        _stopScan();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StatusScreen(widget._ble)),
        );
      }
    });
  }

  void _startScan() {
    WakelockPlus.enable();
    bleScanner.startScan([widget.scanUuid]);

    if (Settings.getValue<bool>("key-infinite-scan") == false) {
      // Todo - fix me
      scanTimer = Timer(const Duration(seconds: 10), _stopScan);
    }
  }

  void _stopScan() {
    scanTimer?.cancel();
    WakelockPlus.disable();
    bleScanner.stopScan();
  }

  Widget _buildDeviceCard(device) => Card(
        child: ListTile(
          title: Text(device.name),
          subtitle: Text("${device.id}\nRSSI: ${device.rssi}"),
          leading: const Icon(Icons.bluetooth_rounded),
          onTap: () {
            _stopScan();
            widget.onDeviceSelected(device, context);
          },
        ),
      );

  Widget _buildDevicesList() {
    final devices = bleScanner.state.discoveredDevices;
    final additionalElement = bleScanner.state.scanIsInProgress ? 1 : 0;

    return ListView.builder(
      itemCount: devices.length + additionalElement,
      itemBuilder: (context, index) => index != devices.length
          ? _buildDeviceCard(devices[index])
          : Padding(
              padding: const EdgeInsets.all(25.0),
              child: JumpingDots(
                color: Colors.grey,
                radius: 6,
                innerPadding: 5,
              ),
            ),
    );
  }

  Widget _buildScanButton() => FilledButton.icon(
        icon: const Icon(Icons.search_rounded),
        label: Text(tr('Scan')),
        onPressed: !bleScanner.state.scanIsInProgress ? _startScan : null,
      );

  Widget _buildStopButton() => FilledButton.icon(
        icon: const Icon(Icons.search_off_rounded),
        label: Text(tr('Stop')),
        onPressed: bleScanner.state.scanIsInProgress ? _stopScan : null,
      );

  Widget _buildControlButtons() => SizedBox(
        height: 50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildScanButton(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStopButton(),
            ),
          ],
        ),
      );

  Widget _buildPortrait() => Column(
        children: [
          Expanded(
            child: _buildDevicesList(),
          ),
          const SizedBox(height: 8),
          _buildControlButtons(),
        ],
      );

  Widget _buildLandscape() => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildDevicesList(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildControlButtons(),
          ),
        ],
      );

  @override
  void initState() {
    super.initState();
    bleScanner = BleScanner(widget._ble);
    widget._ble.statusStream.listen(_evaluateBleStatus);
    _evaluateBleStatus(widget._ble.status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: MediaQuery.of(context).orientation == Orientation.portrait,
      appBar: AppBar(
        title: Text(tr('Devices')),
        centerTitle: true,
        actions: (widget.settingsWidget != null)
            ? [
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () async {
                    _stopScan();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => widget.settingsWidget!,
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16.0),
        child: StreamBuilder<BleScanState>(
          stream: bleScanner.stateStream,
          builder: (context, snapshot) => OrientationBuilder(
            builder: (context, orientation) =>
                orientation == Orientation.portrait ? _buildPortrait() : _buildLandscape(),
          ),
        ),
      ),
    );
  }
}
