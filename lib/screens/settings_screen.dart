import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/device_provider.dart';
import '../providers/theme_provider.dart';
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
  ThemeMode? _themeMode;
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final username = StorageService.getUsername();
    final deviceName = StorageService.getDeviceName();
    final pollingInterval = StorageService.getPollingInterval();
    final themeMode = StorageService.getThemeMode() ?? ThemeMode.system;
    final downloadPath = StorageService.getDownloadPath();
    final defaultPath = await StorageService.getDefaultDownloadDirectory();

    setState(() {
      _username = username;
      _deviceName = deviceName;
      _pollingInterval = pollingInterval;
      _themeMode = themeMode;
      _downloadPath = downloadPath ?? defaultPath;
    });
  }

  Future<void> _pickDownloadFolder() async {
    String? selectedDirectory;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms - use file_picker to select directory
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
    } else {
      // Mobile platforms - show dialog with options
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose download location:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Default (Downloads)'),
                onTap: () => Navigator.of(context).pop('default'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_special),
                title: const Text('Documents'),
                onTap: () => Navigator.of(context).pop('documents'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (result == 'default') {
        selectedDirectory = await StorageService.getDefaultDownloadDirectory();
      } else if (result == 'documents') {
        // Use documents directory
        final dir = await StorageService.getDefaultDownloadDirectory();
        selectedDirectory = dir; // This already defaults to appropriate location
      }
    }

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      await StorageService.saveDownloadPath(selectedDirectory);
      setState(() {
        _downloadPath = selectedDirectory;
      });
      if (mounted) {
        Helpers.showSnackBar(context, 'Download location updated');
      }
    }
  }

  Future<void> _resetDownloadPath() async {
    await StorageService.saveDownloadPath(null);
    final defaultPath = await StorageService.getDefaultDownloadDirectory();
    setState(() {
      _downloadPath = defaultPath;
    });
    if (mounted) {
      Helpers.showSnackBar(context, 'Download location reset to default');
    }
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

  void _clearLocalCache() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Clear Local Cache',
      'This will clear all cached messages and devices from your device. '
      'Messages will be re-fetched from the ESP32 server when you reconnect.\n\n'
      'Continue?',
    );

    if (confirmed) {
      await context.read<ChatProvider>().clearMessages();
      await context.read<DeviceProvider>().clearDevices();
      // Refresh to get data from server
      await context.read<ChatProvider>().fetchMessages();
      await context.read<DeviceProvider>().fetchDevices();
      Helpers.showSnackBar(context, 'Local cache cleared');
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              subtitle: const Text('Follow device theme'),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeProvider>().setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeProvider>().setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeProvider>().setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System Default';
    }
  }

  void _clearAllData() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Clear All Data',
      'This will permanently delete all local data including:\n'
      '• All cached messages\n'
      '• All device information\n'
      '• Your username and device name\n'
      '• All app settings\n\n'
      'You will be logged out and need to register again.\n\n'
      'Continue?',
    );

    if (confirmed) {
      await StorageService.clearAllData();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
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

          // Appearance Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Theme'),
                    subtitle: Text(_getThemeModeText(_themeMode ?? ThemeMode.system)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showThemeDialog,
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

          // File Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<String>(
                    future: StorageService.getDownloadDirectory(),
                    builder: (context, snapshot) {
                      final displayPath = snapshot.data ?? _downloadPath ?? 'Loading...';
                      return ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text('Download Location'),
                        subtitle: Text(
                          displayPath,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _pickDownloadFolder,
                      );
                    },
                  ),
                  FutureBuilder<String>(
                    future: StorageService.getDefaultDownloadDirectory(),
                    builder: (context, snapshot) {
                      final defaultPath = snapshot.data ?? '';
                      if (_downloadPath != null && _downloadPath != defaultPath) {
                        return ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text('Reset to Default'),
                          subtitle: const Text('Use default download location'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _resetDownloadPath,
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final storageInfo = StorageService.getStorageInfo();
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.storage),
                            title: const Text('Storage Information'),
                            subtitle: Text(
                              '${storageInfo['messageCount'] ?? 0} messages stored locally\n'
                              '${storageInfo['deviceCount'] ?? 0} devices known',
                            ),
                          ),
                          const Divider(),
                        ],
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Clear Message History'),
                    subtitle: const Text(
                      'Remove all messages from local device storage\n'
                      'Note: Messages on ESP32 server remain',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _clearMessageHistory,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep),
                    title: const Text('Clear Local Cache'),
                    subtitle: const Text(
                      'Clear all cached messages and devices\n'
                      'Data will be re-fetched from ESP32 server',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _clearLocalCache,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: const Text('Clear All Data'),
                    subtitle: const Text(
                      'Remove all local data and log out\n'
                      'This includes messages, devices, and settings',
                    ),
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
