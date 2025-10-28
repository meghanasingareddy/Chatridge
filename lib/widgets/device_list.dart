import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/connectivity_provider.dart';
import '../models/device.dart';

class DeviceList extends StatelessWidget {
  const DeviceList({super.key, this.onDeviceSelected});

  final Function(String?)? onDeviceSelected;

  @override
  Widget build(BuildContext context) {
    final isConnected =
        context.watch<ConnectivityProvider>().isConnectedToChatridge;
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        if (!isConnected) {
          return const Center(
            child: Text('Connect to Chatridge to see devices',
                style: TextStyle(color: Colors.grey)),
          );
        }
        final devices = deviceProvider.devices;

        if (devices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.device_unknown,
                  size: 32,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'No devices found',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return DeviceCard(
              device: device,
              onDeviceSelected: onDeviceSelected,
            );
          },
        );
      },
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    this.onDeviceSelected,
  });
  final Device device;
  final Function(String?)? onDeviceSelected;

  void _showPrivateMessageOptions(BuildContext context, Device device) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: device.isOnline
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    child: Icon(
                      device.isOnline
                          ? Icons.phone_android
                          : Icons.phone_android_outlined,
                      color: device.isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          device.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: device.isOnline ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Private Message'),
              onTap: () {
                Navigator.pop(context);
                // Trigger private messaging by calling a callback
                _startPrivateMessage(context, device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Device Info'),
              onTap: () {
                Navigator.pop(context);
                _showDeviceInfo(context, device);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startPrivateMessage(BuildContext context, Device device) {
    // Use the callback to notify parent widget
    onDeviceSelected?.call(device.name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Now messaging ${device.name} privately'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeviceInfo(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${device.isOnline ? "Online" : "Offline"}'),
            Text('Last seen: ${device.statusText}'),
            if (device.ip.isNotEmpty) Text('IP: ${device.ip}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            // Implement device selection for private messaging
            _showPrivateMessageOptions(context, device);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Device Icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor: device.isOnline
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  child: Icon(
                    device.isOnline
                        ? Icons.phone_android
                        : Icons.phone_android_outlined,
                    color: device.isOnline ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ),

                const SizedBox(height: 8),

                // Device Name
                Text(
                  device.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: device.isOnline ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    device.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Last seen
                Text(
                  device.statusText,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
