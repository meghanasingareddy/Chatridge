import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _username;
  String? _deviceName;
  int _pollingInterval = 2;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final username = StorageService.getUsername();
    final deviceName = StorageService.getDeviceName();
    final pollingInterval = StorageService.getPollingInterval();

    setState(() {
      _username = username;
      _deviceName = deviceName;
      _pollingInterval = pollingInterval;
    });
  }

  void _showChangeUsernameDialog() {
    final controller = TextEditingController(text: _username ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter new username',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newUsername = controller.text.trim();
              if (newUsername.isNotEmpty &&
                  Helpers.isValidUsername(newUsername)) {
                setState(() {
                  _username = newUsername;
                });
                StorageService.saveUsername(newUsername);
                Navigator.of(context).pop();
                Helpers.showSnackBar(context, 'Username updated');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeDeviceNameDialog() {
    final controller = TextEditingController(text: _deviceName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            hintText: 'Enter new device name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newDeviceName = controller.text.trim();
              if (newDeviceName.isNotEmpty &&
                  Helpers.isValidDeviceName(newDeviceName)) {
                setState(() {
                  _deviceName = newDeviceName;
                });
                StorageService.saveDeviceName(newDeviceName);
                Navigator.of(context).pop();
                Helpers.showSnackBar(context, 'Device name updated');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPollingIntervalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Polling Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How often to check for new messages:'),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final seconds = (index + 1) * 2;
              return RadioListTile<int>(
                title: Text('$seconds seconds'),
                value: seconds,
                groupValue: _pollingInterval,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pollingInterval = value;
                    });
                    StorageService.setPollingInterval(value);
                    context.read<ChatProvider>().setPollingInterval(value);
                    Navigator.of(context).pop();
                    Helpers.showSnackBar(context, 'Polling interval updated');
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _clearMessageHistory() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Clear Message History',
      'Are you sure you want to clear all messages? This action cannot be undone.',
    );

    if (confirmed) {
      await context.read<ChatProvider>().clearMessages();
      Helpers.showSnackBar(context, 'Message history cleared');
    }
  }

  void _clearAllData() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Clear All Data',
      'Are you sure you want to clear all data? This will log you out and clear all messages and settings.',
    );

    if (confirmed) {
      await StorageService.clearAllData();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Username'),
                    subtitle: Text(_username ?? 'Not set'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showChangeUsernameDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: const Text('Device Name'),
                    subtitle: Text(_deviceName ?? 'Not set'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showChangeDeviceNameDialog,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chat Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chat Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      return SwitchListTile(
                        title: const Text('Auto Polling'),
                        subtitle:
                            const Text('Automatically check for new messages'),
                        value: chatProvider.autoPolling,
                        onChanged: (value) {
                          chatProvider.toggleAutoPolling();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Polling Interval'),
                    subtitle: Text('$_pollingInterval seconds'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showPollingIntervalDialog,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data Management Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Clear Message History'),
                    subtitle:
                        const Text('Remove all messages from local storage'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _clearMessageHistory,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: const Text('Clear All Data'),
                    subtitle: const Text('Remove all data and log out'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _clearAllData,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Info Section
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  ListTile(
                    leading: Icon(Icons.wifi),
                    title: Text('Network'),
                    subtitle: Text('Chatridge (192.168.4.1)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
