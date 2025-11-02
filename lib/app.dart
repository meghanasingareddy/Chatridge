import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/conversations_screen.dart';
import 'providers/connectivity_provider.dart';
import 'services/storage_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // Check if user is already registered
    final username = StorageService.getUsername();
    final deviceName = StorageService.getDeviceName();

    if (username != null && deviceName != null) {
      // User is registered, go to conversations screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ConversationsScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        // Allow app to open offline and show stored chats.
        // If not connected, user can still navigate to Connect from Settings.
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Title
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Color(0xFF3498DB),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chatridge',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Offline Local WiFi Messaging',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Connection Status
                  Container(
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
                    child: Column(
                      children: [
                        Icon(
                          connectivityProvider.isConnectedToChatridge
                              ? Icons.wifi
                              : Icons.wifi_off,
                          color: connectivityProvider.isConnectedToChatridge
                              ? Colors.green
                              : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          connectivityProvider.isConnectedToChatridge
                              ? 'Connected to Chatridge Network'
                              : 'Not connected to Chatridge Network',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!connectivityProvider.isConnectedToChatridge) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Please connect to WiFi network "Chatridge" (password: 12345678)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Test Connection Button
                  SizedBox(
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
                  ),

                  const SizedBox(height: 16),

                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
