import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class DeviceCardWidget extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DeviceCardWidget({
    Key? key,
    required this.device,
    this.onConnect,
    this.onDisconnect,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isConnected = device['isConnected'] ?? false;
    final int signalStrength = device['signalStrength'] ?? 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: isConnected
              ? Border.all(color: AppTheme.successLight, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Device Icon
                CustomIconWidget(
                  iconName: device['type']?.toLowerCase() == 'arduino'
                      ? 'memory'
                      : 'developer_board',
                  color: isConnected
                      ? AppTheme.successLight
                      : AppTheme.lightTheme.primaryColor,
                  size: 8.w,
                ),
                SizedBox(width: 4.w),
                // Device Name and MAC
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['name'] ?? 'Unknown Device',
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        device['macAddress'] ?? 'XX:XX:XX:XX:XX:XX',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                                color: AppTheme.textSecondaryLight,
                                fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                // Signal Strength
                Row(
                  children: List.generate(4, (index) {
                    return Icon(
                      index < signalStrength
                          ? Icons.signal_cellular_alt
                          : Icons.signal_cellular_alt_outlined,
                      color: index < signalStrength
                          ? (signalStrength > 2
                              ? AppTheme.successLight
                              : AppTheme.warningLight)
                          : AppTheme.textDisabledLight,
                      size: 4.w,
                    );
                  }),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // Action Buttons
            Row(
              children: [
                if (isConnected)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDisconnect,
                      icon: CustomIconWidget(iconName: 'link_off', size: 4.w),
                      label: const Text('Disconnect'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorLight,
                          side: BorderSide(color: AppTheme.errorLight)),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConnect,
                      icon: CustomIconWidget(
                          iconName: 'bluetooth_connected',
                          color: Colors.white,
                          size: 4.w),
                      label: const Text('Connect'),
                    ),
                  ),
                SizedBox(width: 2.w),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: CustomIconWidget(iconName: 'info_outline', size: 4.w),
                    label: const Text('Details'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
