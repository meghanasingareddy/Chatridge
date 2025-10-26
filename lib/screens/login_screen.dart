import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _deviceNameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() async {
    final username = StorageService.getUsername();
    final deviceName = StorageService.getDeviceName();

    if (username != null) _usernameController.text = username;
    if (deviceName != null) _deviceNameController.text = deviceName;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _registerDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final username = _usernameController.text.trim();
      final deviceName = _deviceNameController.text.trim();

      // Save user data locally
      await StorageService.saveUserInfo(username, deviceName);

      // Register with ESP32 server
      final apiService = ApiService();
      final success = await apiService.registerDevice(deviceName);

      if (success) {
        // Navigate to chat screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        }
      } else {
        setState(() {
          _error = 'Failed to register with Chatridge server';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Chatridge'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status
                Consumer<ConnectivityProvider>(
                  builder: (context, connectivityProvider, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: connectivityProvider.isConnectedToChatridge
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: connectivityProvider.isConnectedToChatridge
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            connectivityProvider.getConnectionStatusIcon(),
                            color:
                                connectivityProvider.getConnectionStatusColor(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  connectivityProvider
                                      .getConnectionStatusText(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!connectivityProvider
                                    .isConnectedToChatridge) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Connect to WiFi network "Chatridge" (password: 12345678)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Manual Connection Test Button
                Consumer<ConnectivityProvider>(
                  builder: (context, connectivityProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await connectivityProvider.refreshConnectivity();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                connectivityProvider.isConnectedToChatridge
                                    ? 'Successfully connected to Chatridge!'
                                    : 'Could not connect to Chatridge server. Please check your WiFi connection.',
                              ),
                              backgroundColor:
                                  connectivityProvider.isConnectedToChatridge
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Test Connection'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Username Input
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (!Helpers.isValidUsername(value.trim())) {
                      return 'Username must be 1-20 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Device Name Input
                TextFormField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    hintText: 'Enter your device name',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a device name';
                    }
                    if (!Helpers.isValidDeviceName(value.trim())) {
                      return 'Device name must be 1-30 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Error Message
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Register Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerDevice,
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Registering...'),
                            ],
                          )
                        : const Text(
                            'Register & Start Chatting',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Help Text
                const Text(
                  'Make sure you are connected to the Chatridge WiFi network before registering.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
