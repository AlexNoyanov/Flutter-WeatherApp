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

  // print("DATA =  $data");

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
      backgroundColor: AppColors.deepSpace,
      appBar: AppBar(backgroundColor: AppColors.deepSpace),
      body: Container(
        width: double.infinity,
        color: AppColors.deepSpace,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, // ← Left align!
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    _fullWeatherData?.locationName ?? 'Loading...',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.96,
                      height: 1.1,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFD3E2FF)],
                        ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    _getFormattedDate(), // Use your dynamic date
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.16,
                      color: Color(0xFF8A9BB5),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    height: 120,
                    width: 380,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 5),
                            Text(
                              _fullWeatherData != null
                                  ? '${_fullWeatherData!.temperature.toStringAsFixed(1)}°'
                                  : '22.5',
                              style: TextStyle(
                                fontSize: 78,
                                fontWeight:
                                    FontWeight.w500, // Medium weight (500)
                                fontFamily:
                                    'SpaceGrotesk', // Must add to pubspec.yaml
                                height: 1.0, // line-height: 1
                                letterSpacing: -4.0, // -4px letter spacing
                                foreground: Paint()
                                  ..shader =
                                      LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: const [
                                          Color(0xFFFFFFFF), // White
                                          Color(0xFFB8CCF0), // Soft blue
                                        ],
                                        stops: const [
                                          0.3,
                                          1.0,
                                        ], // 30% white, 100% blue
                                      ).createShader(
                                        const Rect.fromLTWH(0, 0, 200, 100),
                                      ),
                              ),
                            ),
                            Text(
                              '°C',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight:
                                    FontWeight.w500, // Medium weight (500)
                                fontFamily:
                                    'SpaceGrotesk', // Must add to pubspec.yaml
                                height: 1.0, // line-height: 1
                                letterSpacing: -4.0, // -4px letter spacing
                                foreground: Paint()
                                  ..shader =
                                      LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: const [
                                          Color(0xFFFFFFFF), // White
                                          Color(0xFFB8CCF0), // Soft blue
                                        ],
                                        stops: const [
                                          0.3,
                                          1.0,
                                        ], // 30% white, 100% blue
                                      ).createShader(
                                        const Rect.fromLTWH(0, 0, 200, 100),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Container(
                              height: 80,
                              // width: 120, // Remove fixed width - let it size to content
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF121820).withOpacity(
                                  0.75,
                                ), // Card Dark with 75% opacity
                                borderRadius: BorderRadius.circular(40.0),
                                border: Border.all(
                                  color: const Color(0xFF58C4FF).withOpacity(
                                    0.25,
                                  ), // Bright blue with 25% opacity
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF002864,
                                    ).withOpacity(0.5), // Dark blue shadow
                                    offset: const Offset(0, 8),
                                    blurRadius: 12,
                                    spreadRadius:
                                        -8, // Negative spread = smaller shadow
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min, // Shrink to fit content
                                children: [
                                  const Text(
                                    '☁️',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  // const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      Text(
                                        _fullWeatherData?.weatherDescription ??
                                            'overcast',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Color(
                                            0xFFD6EAFF,
                                          ), // Light blue white
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      Text(
                                        _fullWeatherData?.weatherDescription ??
                                            'clouds',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Color(
                                            0xFFD6EAFF,
                                          ), // Light blue white
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _precidWidget('50', 'no rain', '0', 'skyType'),
                    _humidityWidget('69', 3.2),
                  ],
                ),
              ],
            ), // Spacing from top
          ],
        ),
      ),
    );
  }

  Widget _precidWidget(precip, rainStatus, waterLevel, skyType) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Container(
        height: 180,
        width: 180,
        // width: 120, // Remove fixed width - let it size to content
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(
            0xFF121820,
          ).withOpacity(0.75), // Card Dark with 75% opacity
          borderRadius: BorderRadius.circular(40.0),
          border: Border.all(
            color: const Color(
              0xFF58C4FF,
            ).withOpacity(0.25), // Bright blue with 25% opacity
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF002864,
              ).withOpacity(0.5), // Dark blue shadow
              offset: const Offset(0, 8),
              blurRadius: 12,
              spreadRadius: -8, // Negative spread = smaller shadow
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💧',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD6EAFF), // Light blue white
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'PRECIP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD6EAFF), // Light blue white
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$precip',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w500, // Medium weight (500)
                      fontFamily: 'SpaceGrotesk', // Must add to pubspec.yaml
                      height: 1.0, // line-height: 1
                      letterSpacing: -4.0, // -4px letter spacing
                      foreground: Paint()
                        ..shader = LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Color(0xFFFFFFFF), // White
                            Color(0xFFB8CCF0), // Soft blue
                          ],
                          stops: const [0.3, 1.0], // 30% white, 100% blue
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 100)),
                    ),
                  ),
                  Text(
                    '  %',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500, // Medium weight (500)
                      fontFamily: 'SpaceGrotesk', // Must add to pubspec.yaml
                      height: 1.0, // line-height: 1
                      letterSpacing: -4.0, // -4px letter spacing
                      foreground: Paint()
                        ..shader = LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Color(0xFFFFFFFF), // White
                            Color(0xFFB8CCF0), // Soft blue
                          ],
                          stops: const [0.3, 1.0], // 30% white, 100% blue
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 100)),
                    ),
                  ),
                ],
              ),
              Text(
                rainStatus, // Use your dynamic date
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.16,
                  color: Color(0xFF8A9BB5),
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    waterLevel, // Use your dynamic date
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.16,
                      color: Color(0xFF8A9BB5),
                      fontFamily: 'Inter',
                    ),
                  ),
                  Icon(
                    Icons.fiber_manual_record,
                    size: 10.0,
                    color: Color(0xFF8A9BB5),
                  ),
                  Text(
                    skyType, // Use your dynamic date
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.16,
                      color: Color(0xFF8A9BB5),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _humidityWidget(humidity, double dewPoint) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Container(
        height: 180,
        width: 180,
        // width: 120, // Remove fixed width - let it size to content
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(
            0xFF121820,
          ).withOpacity(0.75), // Card Dark with 75% opacity
          borderRadius: BorderRadius.circular(40.0),
          border: Border.all(
            color: const Color(
              0xFF58C4FF,
            ).withOpacity(0.25), // Bright blue with 25% opacity
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF002864,
              ).withOpacity(0.5), // Dark blue shadow
              offset: const Offset(0, 8),
              blurRadius: 12,
              spreadRadius: -8, // Negative spread = smaller shadow
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💨',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD6EAFF), // Light blue white
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'HUMIDITY',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD6EAFF), // Light blue white
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$humidity',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w500, // Medium weight (500)
                      fontFamily: 'SpaceGrotesk', // Must add to pubspec.yaml
                      height: 1.0, // line-height: 1
                      letterSpacing: -4.0, // -4px letter spacing
                      foreground: Paint()
                        ..shader = LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Color(0xFFFFFFFF), // White
                            Color(0xFFB8CCF0), // Soft blue
                          ],
                          stops: const [0.3, 1.0], // 30% white, 100% blue
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 100)),
                    ),
                  ),
                  Text(
                    '  %',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500, // Medium weight (500)
                      fontFamily: 'SpaceGrotesk', // Must add to pubspec.yaml
                      height: 1.0, // line-height: 1
                      letterSpacing: -4.0, // -4px letter spacing
                      foreground: Paint()
                        ..shader = LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Color(0xFFFFFFFF), // White
                            Color(0xFFB8CCF0), // Soft blue
                          ],
                          stops: const [0.3, 1.0], // 30% white, 100% blue
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 100)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 35),
              LinearProgressIndicator(
                value: dewPoint / 10, // Value between 0.0 and 1.0
              ),
              Row(
                children: [
                  Text(
                    'dew point ', // Use your dynamic date
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.16,
                      color: Color(0xFF8A9BB5),
                      fontFamily: 'Inter',
                    ),
                  ),

                  Text(
                    dewPoint.toString(), // Use your dynamic date
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.16,
                      color: Color(0xFF8A9BB5),
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    '°', // Use your dynamic date
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.16,
                      color: Color(0xFF8A9BB5),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
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
