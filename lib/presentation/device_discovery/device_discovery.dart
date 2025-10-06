import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/bluetooth_service.dart';
import './widgets/connection_dialog_widget.dart';
import './widgets/device_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/manual_pairing_dialog_widget.dart';
import './widgets/skeleton_device_card_widget.dart';

class DeviceDiscovery extends StatefulWidget {
  const DeviceDiscovery({Key? key}) : super(key: key);

  @override
  State<DeviceDiscovery> createState() => _DeviceDiscoveryState();
}

class _DeviceDiscoveryState extends State<DeviceDiscovery>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final BlueBridgeBluetoothService _bluetoothService = BlueBridgeBluetoothService();
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  bool _isScanning = false;
  List<ScanResult> _discoveredDevices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Listen to scan results
    _scanResultsSubscription = _bluetoothService.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          // Filter out devices with no name
          _discoveredDevices =
              results.where((r) => r.device.platformName.isNotEmpty).toList();
        });
      }
    });

    // Listen to scanning state
    _isScanningSubscription = _bluetoothService.isScanning.listen((isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
        });
      }
    });

    _refreshDevices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _bluetoothService.stopScan();
    super.dispose();
  }

  Future<void> _refreshDevices() async {
    if (_isScanning) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Start a new scan
    await _bluetoothService.startScan(timeout: const Duration(seconds: 5));
  }

  void _connectToDevice(BluetoothDevice device) {
    // Convert BluetoothDevice to a Map for the dialog
    final deviceData = {
      "name": device.platformName,
      "macAddress": device.remoteId.toString(),
      "type": "Unknown", // You can add logic to determine type
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConnectionDialogWidget(
        device: deviceData,
        onConnect: () async {
          Navigator.of(context).pop();
          await _bluetoothService.connect(device);
          _showConnectionSuccess(deviceData);
          // Trigger a rebuild to update connection state
          setState(() {});
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _disconnectFromDevice(BluetoothDevice device) async {
    await _bluetoothService.disconnect(device);
    final deviceName = device.platformName;
    setState(() {}); // Trigger rebuild
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Disconnected from $deviceName'),
        backgroundColor: AppTheme.warningLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showConnectionSuccess(Map<String, dynamic> device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Connected to ${device['name']}',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Open Chat',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/bluebridge-chat');
          },
        ),
      ),
    );
  }

  void _showDeviceDetails(ScanResult scanResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDeviceDetailsSheet(scanResult),
    );
  }

  void _showDeviceContextMenu(ScanResult scanResult) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildContextMenuSheet(scanResult),
    );
  }

  void _showManualPairingDialog() {
    showDialog(
      context: context,
      builder: (context) => ManualPairingDialogWidget(
        onPair: (macAddress) {
          Navigator.of(context).pop();
          _pairDeviceByMac(macAddress);
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _pairDeviceByMac(String macAddress) {
    // Simulate pairing process
    // In a real app, you would try to connect to this MAC address.
    // This is a placeholder for now.
    // Note: flutter_blue_plus identifies devices by a RemoteId, which might not
    // always be the public MAC address. This feature requires more advanced handling.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Device added: $macAddress'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Tab Bar
            Container(
              color: AppTheme.lightTheme.colorScheme.surface,
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Row(
                      children: [
                        Text(
                          'BlueBridge',
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.lightTheme.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _refreshDevices,
                          icon: _isScanning
                              ? SizedBox(
                                  width: 6.w,
                                  height: 6.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.lightTheme.primaryColor,
                                    ),
                                  ),
                                )
                              : CustomIconWidget(
                                  iconName: 'refresh',
                                  color: AppTheme.lightTheme.primaryColor,
                                  size: 6.w,
                                ),
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Discovery'),
                      Tab(text: 'Messages'),
                      Tab(text: 'Settings'),
                    ],
                  ),
                ],
              ),
            ),
            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiscoveryTab(),
                  _buildMessagesTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showManualPairingDialog,
              child: CustomIconWidget(
                iconName: 'add_link',
                color: Colors.white,
                size: 6.w,
              ),
            )
          : null,
    );
  }

  Widget _buildDiscoveryTab() {
    return RefreshIndicator(
      onRefresh: _refreshDevices,
      color: AppTheme.lightTheme.primaryColor,
      child: Column(
        children: [
          // Sticky Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'bluetooth_searching',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Nearby Devices',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const Spacer(),
                if (_isScanning)
                  Text(
                    'Scanning...',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Device List
          Expanded(
            child: _isScanning
                ? _buildScanningState()
                : _discoveredDevices.isEmpty
                    ? EmptyStateWidget(onRefresh: _refreshDevices)
                    : _buildDeviceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Column(
      children: [
        SizedBox(height: 2.h),
        Text(
          'Searching for devices...',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) => const SkeletonDeviceCardWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 10.h),
      itemCount: _discoveredDevices.length,
      itemBuilder: (context, index) {
        final scanResult = _discoveredDevices[index];
        final device = scanResult.device;

        // Convert ScanResult to the Map format expected by DeviceCardWidget
        final deviceData = {
          "name": device.platformName,
          "macAddress": device.remoteId.toString(),
          "type": "Unknown", // Can be inferred from name or advertisement data
          "signalStrength": _getSignalStrength(scanResult.rssi),
          "isConnected": device.isConnected,
          "lastSeen": DateTime.now(),
          "deviceInfo": {
            "firmware": "Unknown",
            "features": ["BLE"]
          }
        };

        return DeviceCardWidget(
          device: deviceData,
          onConnect: () => _connectToDevice(device),
          onDisconnect: () => _disconnectFromDevice(device),
          onTap: () => _showDeviceDetails(scanResult),
          onLongPress: () => _showDeviceContextMenu(scanResult),
        );
      },
    );
  }

  Widget _buildDeviceDetailsSheet(ScanResult scanResult) {
    final device = scanResult.device;
    final isConnected = device.isConnected;
    final signalStrength = _getSignalStrength(scanResult.rssi);

    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.textDisabledLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Device Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName:
                      device.platformName.toLowerCase().contains('arduino')
                          ? 'memory'
                          : 'developer_board',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 8.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.platformName,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      device.remoteId.toString(),
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryLight,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Device Info
          _buildInfoRow('Type', _getDeviceTypeFromName(device.platformName)),
          _buildInfoRow('Signal Strength',
              '$signalStrength/4 bars (RSSI: ${scanResult.rssi} dBm)'),
          _buildInfoRow('Status', isConnected ? 'Connected' : 'Available'),
          _buildInfoRow('Last Seen', _formatLastSeen(DateTime.now())),
          if (scanResult.advertisementData.serviceUuids.isNotEmpty) ...[
            _buildInfoRow('Service UUIDs',
                scanResult.advertisementData.serviceUuids.join('\n')),
          ],
          if (true) ...[
            // Placeholder for real features
            SizedBox(height: 2.h),
            Text(
              'Features',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: (["BLE", "GATT"]) // Example features
                  .map((feature) => Chip(
                        label: Text(
                          feature,
                          style: AppTheme.lightTheme.textTheme.labelSmall,
                        ),
                        backgroundColor: AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.1),
                      ))
                  .toList(),
            ),
          ],
          SizedBox(height: 4.h),
          // Connected Devices Section for Hub devices
          if (_canShowConnectedDevices(device.platformName)) ...[
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'hub',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Device Hub',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'This device can connect to other devices and act as a hub.',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              height: 5.h,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/connected-devices',
                    arguments: {
                      'device': device
                    }, // Needs adjustment for BluetoothDevice
                  );
                },
                icon: CustomIconWidget(
                  iconName: 'device_hub',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 5.w,
                ),
                label: Text(
                  'View Connected Devices',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.lightTheme.primaryColor,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: isConnected
                  ? () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/bluebridge-chat');
                    }
                  : () {
                      Navigator.pop(context);
                      _connectToDevice(scanResult.device);
                    },
              child: Text(
                isConnected ? 'Open Chat' : 'Connect Device',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canShowConnectedDevices(String deviceName) {
    // Show for devices that have hub capabilities
    return deviceName.toLowerCase().contains('hub') ||
        deviceName.toLowerCase().contains('bridge');
  }

  Widget _buildContextMenuSheet(ScanResult scanResult) {
    final device = scanResult.device;

    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.textDisabledLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Menu Items
          ListTile(
            leading: CustomIconWidget(
              iconName: 'edit',
              color: AppTheme.lightTheme.primaryColor,
              size: 6.w,
            ),
            title: Text('Rename Device'),
            onTap: () {
              Navigator.pop(context);
              // Implement rename functionality
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'delete_forever',
              color: AppTheme.errorLight,
              size: 6.w,
            ),
            title: Text('Forget Device'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _discoveredDevices
                    .removeWhere((r) => r.device.remoteId == device.remoteId);
              });
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'history',
              color: AppTheme.textSecondaryLight,
              size: 6.w,
            ),
            title: Text('Connection History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/connection-status');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  int _getSignalStrength(int rssi) {
    if (rssi >= -60) {
      return 4; // Excellent
    } else if (rssi >= -70) {
      return 3; // Good
    } else if (rssi >= -80) {
      return 2; // Fair
    } else {
      return 1; // Weak
    }
  }

  String _getDeviceTypeFromName(String name) {
    if (name.toLowerCase().contains('esp32')) {
      return 'ESP32';
    } else if (name.toLowerCase().contains('arduino')) {
      return 'Arduino';
    }
    return 'Generic BLE';
  }

  Widget _buildMessagesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'message',
            color: AppTheme.textDisabledLight,
            size: 20.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Messages',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Connect to a device to start messaging',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/message-history');
            },
            child: Text(
              'View Message History',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        ListTile(
          leading: CustomIconWidget(
            iconName: 'bluetooth_settings',
            color: AppTheme.lightTheme.primaryColor,
            size: 6.w,
          ),
          title: Text('Bluetooth Settings'),
          subtitle: Text('Manage Bluetooth preferences'),
          trailing: CustomIconWidget(
            iconName: 'chevron_right',
            color: AppTheme.textSecondaryLight,
            size: 5.w,
          ),
          onTap: () {
            Navigator.pushNamed(context, '/bluetooth-permissions');
          },
        ),
        ListTile(
          leading: CustomIconWidget(
            iconName: 'security',
            color: AppTheme.lightTheme.primaryColor,
            size: 6.w,
          ),
          title: Text('Security'),
          subtitle: Text('Encryption and privacy settings'),
          trailing: CustomIconWidget(
            iconName: 'chevron_right',
            color: AppTheme.textSecondaryLight,
            size: 5.w,
          ),
          onTap: () {
            // Navigate to security settings
          },
        ),
        ListTile(
          leading: CustomIconWidget(
            iconName: 'info',
            color: AppTheme.lightTheme.primaryColor,
            size: 6.w,
          ),
          title: Text('About'),
          subtitle: Text('App version and information'),
          trailing: CustomIconWidget(
            iconName: 'chevron_right',
            color: AppTheme.textSecondaryLight,
            size: 5.w,
          ),
          onTap: () {
            // Show about dialog
          },
        ),
      ],
    );
  }
}
