import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check if location services are enabled
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request location permission
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // Permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false; // Permissions are permanently denied
    }

    return true; // Permissions are granted
  }

  // Get current position
  static Future<Position> getCurrentLocation() async {
    // Check if location services are enabled
    bool isEnabled = await isLocationEnabled();
    if (!isEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check and request permissions
    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Location permissions are denied');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
