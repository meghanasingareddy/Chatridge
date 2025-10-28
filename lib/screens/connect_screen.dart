import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../utils/permissions.dart';
import '../services/wifi_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _busy = false;
  String _status = 'Not connected';

  Future<void> _requestPermissions() async {
    setState(() => _busy = true);
    try {
      await Permissions.requestAllPermissions();
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _status = 'Connecting to ESP Wi‑Fi…';
    });
    final wifiOk = await WifiService().ensureConnectedToEsp();
    if (!mounted) return;
    if (!wifiOk) {
      setState(() {
        _busy = false;
        _status = 'Failed to join ESP Wi‑Fi. Connect manually and retry.';
      });
      return;
    }

    setState(() => _status = 'Testing server…');
    final ok =
        await context.read<ConnectivityProvider>().checkChatridgeConnection();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status =
          ok ? 'Connected' : 'ESP server unreachable. Open the app on ESP.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to Chatridge')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              'Step 1: Permissions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _requestPermissions,
              child: const Text('Grant storage/camera/photos permissions'),
            ),
            const SizedBox(height: 24),
            Text(
              'Step 2: Connect to ESP Wi‑Fi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _busy ? null : _connect,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.wifi),
              label: const Text('Connect to Chatridge AP'),
            ),
            const SizedBox(height: 12),
            Text(_status),
            const Spacer(),
            Consumer<ConnectivityProvider>(
              builder: (context, cp, _) => ElevatedButton(
                onPressed: cp.isConnectedToChatridge && !_busy
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
