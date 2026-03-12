import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:weather_app/location_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Colors for redesign:
class AppColors {
  static const Color deepSpace = Color(0xFF0A0E14);
  static const Color cardDark = Color(0xFF121820);
  static const Color metricCard = Color(0xFF0C141E);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color steelBlue = Color(0xFF8A9BB5);
  static const Color brightBlue = Color(0xFF58C4FF);
  static const Color electricBlue = Color(0xFF48B5FF);
  // Add all colors from my previous list
}

// Color	Hex	Where to Use
// Deep Space	#0A0E14	Main app background (scaffold backgroundColor)
// Card Dark	#121820 (75% opacity)	Main weather card - the big rounded container
// Metric Card	#0C141E (60% opacity)	Individual metric cards (precipitation, humidity, wind)

typedef WeatherData = ({
  double temperature,
  double humidity,
  String weatherDescription,
  double precipitation,
  double windSpeed,
  String locationName,
  DateTime currentDate,
});

Future<WeatherData> getWeather(double lat, double lon) async {
  print('=== GETTING WEATHER UPDATE ===');
  final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  final url = dotenv.env['OPENWEATHER_BASE_URL'] ?? '';

  final response = await http.get(Uri.parse(url));
  final data = json.decode(response.body);

  print("DATA =  $data");

  final WeatherData weatherData = (
    temperature: (data['main']['temp'] as num).toDouble(),
    humidity: (data['main']['humidity'] as num).toDouble(),
    weatherDescription: data['weather'][0]['description'] as String,
    precipitation: ((data['rain']?['1h'] ?? 0.0) as num).toDouble(),
    windSpeed: (data['wind']['speed'] as num).toDouble(),
    locationName: data['name'] as String? ?? 'Unknown',
    currentDate: DateTime.now(),
  );

  return weatherData;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Weather app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 158, 212, 254),
        ),
      ),
      home: const MyHomePage(), // Remove title parameter
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  WeatherData? _fullWeatherData;
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      // Step 1: Get current location
      print('Getting location...');
      final position = await LocationService.getCurrentLocation();

      print('Location obtained: ${position.latitude}, ${position.longitude}');

      // final weatherData = await getWeather(55.731028, 37.857556);
      final weatherData = await getWeather(
        position.latitude,
        position.longitude,
      );

      print('Weather data obtained: $weatherData');

      // 🔵 USE setState() TO UPDATE UI
      if (mounted) {
        setState(() {
          _fullWeatherData = weatherData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weather: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFormattedDate() {
    if (_fullWeatherData == null) return 'Loading date...';
    return DateFormat(
      'EEEE, d MMMM yyyy HH:mm',
    ).format(_fullWeatherData!.currentDate);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching data
    if (_isLoading) {
      print("LOADING");
      // _loadingState();
      return Scaffold(
        backgroundColor: AppColors.deepSpace,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          title: const Center(child: Text('Weather App')),
          leading: const Icon(Icons.more_vert),
          actions: const [Icon(Icons.add)],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Fetching weather data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 209, 255),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on),
                  Text(_fullWeatherData?.locationName ?? 'Unknown'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getFormattedDate(),
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        leading: const Icon(Icons.more_vert),
        actions: const [Icon(Icons.add)],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _fullWeatherData != null
                  ? '${_fullWeatherData!.temperature.toStringAsFixed(1)}°'
                  : '--°',
              style: TextStyle(
                color: const Color.fromARGB(255, 25, 113, 245).withOpacity(0.6),
                fontSize: 120,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _fullWeatherData?.weatherDescription ?? '--',
                  style: TextStyle(
                    color: const Color.fromARGB(
                      255,
                      113,
                      86,
                      246,
                    ).withOpacity(0.6),
                    fontSize: 25,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.cloud,
                  color: Color.fromARGB(255, 112, 184, 244),
                  size: 80.0,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 120,
              width: 360,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 250, 250),
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildWeatherStat(
                      icon: Icons.umbrella_outlined,
                      value: _fullWeatherData?.precipitation,
                      unit: '%',
                      label: 'Precipitation',
                    ),
                    _buildWeatherStat(
                      icon: Icons.water_drop,
                      value: _fullWeatherData?.humidity,
                      unit: '%',
                      label: 'Humidity',
                    ),
                    _buildWeatherStat(
                      icon: Icons.air,
                      value: _fullWeatherData?.windSpeed,
                      unit: 'km/h',
                      label: 'Wind Speed',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appLoadingAnimation() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        const Text('Loading...'),
      ],
    );
  }

  Widget _buildWeatherStat({
    required IconData icon,
    required double? value,
    required String unit,
    required String label,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(icon),
        Text(value != null ? '${value.toStringAsFixed(1)}$unit' : '--$unit'),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
