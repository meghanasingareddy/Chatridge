// Math utility functions for BlueBridge app
import 'dart:math' as math;

class MathUtils {
  /// Converts degrees to radians
  static double degToRad(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  /// Converts radians to degrees
  static double radToDeg(double radians) {
    return radians * (180 / math.pi);
  }
  
  /// Clamps a value between min and max
  static double clamp(double value, double min, double max) {
    return math.max(min, math.min(max, value));
  }
  
  /// Clamps an integer value between min and max
  static int clampInt(int value, int min, int max) {
    return math.max(min, math.min(max, value));
  }
  
  /// Calculates the distance between two points
  static double distance(double x1, double y1, double x2, double y2) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }
  
  /// Linear interpolation between two values
  static double lerp(double a, double b, double t) {
    return a + (b - a) * clamp(t, 0.0, 1.0);
  }
  
  /// Converts RSSI (signal strength) to signal bars (1-4)
  static int rssiToSignalBars(int rssi) {
    if (rssi >= -60) return 4; // Excellent
    if (rssi >= -70) return 3; // Good
    if (rssi >= -80) return 2; // Fair
    return 1; // Weak
  }
  
  /// Converts signal bars to percentage
  static double signalBarsToPercentage(int bars) {
    return clamp(bars / 4.0, 0.0, 1.0);
  }
  
  /// Calculates percentage between two values
  static double percentage(double value, double min, double max) {
    if (max == min) return 0.0;
    return clamp((value - min) / (max - min), 0.0, 1.0);
  }
  
  /// Rounds to specified decimal places
  static double roundToDecimal(double value, int decimalPlaces) {
    final factor = math.pow(10, decimalPlaces);
    return (value * factor).round() / factor;
  }
  
  /// Calculates Bluetooth range based on RSSI
  static double estimateBluetoothRange(int rssi) {
    // Rough estimation: -40 dBm ≈ 1m, -50 dBm ≈ 3m, -60 dBm ≈ 10m
    final double range = math.pow(10, (-rssi - 40) / 20).toDouble();
    return clamp(range, 0.5, 50.0); // Clamp between 0.5m and 50m
  }
  
  /// Generates a random ID string
  static String generateRandomId([int length = 8]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}