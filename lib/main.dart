import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'weather_api.dart';

// ==================== COLORS ====================
class AppColors {
  static const Color deepSpace = Color(0xFF0A0E14);
  static const Color cardDark = Color(0xFF121820); // use with opacity
  static const Color metricCard = Color(0xFF0C141E); // use with opacity
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color steelBlue = Color(0xFF8A9BB5);
  static const Color brightBlue = Color(0xFF58C4FF);
  static const Color electricBlue = Color(0xFF48B5FF);
  static const Color lightBlue = Color(0xFFA0D0FF);
  static const Color lightBlueWhite = Color(0xFFD6EAFF);
  static const Color mutedBlue = Color(0xFFC7D0DA);
  static const Color dimBlue = Color(0xFF6D88AA);
  static const Color deepBlueGray = Color(0xFF3F5679);
  static const Color mediumBlueGray = Color(0xFF9FB0D0);
}

// ==================== MAIN ====================
void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futuristic Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.deepSpace,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.pureWhite),
          bodyMedium: TextStyle(color: AppColors.steelBlue),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WeatherData? _fullWeatherData;
  WeatherMeta? _weatherMeta;
  bool _isLoading = true;
  String? _errorMessage;

  bool _useEarth = true;
  String _planet = 'mars';
  String _side = 'bright';
  List<String> _planets = const ['mars', 'moon', 'venus', 'mercury', 'jupiter'];

  @override
  void initState() {
    super.initState();
    _initPlanetsAndWeather();
  }

  Future<void> _initPlanetsAndWeather() async {
    try {
      final supported = await fetchSupportedPlanets();
      if (mounted) {
        setState(() {
          _planets = supported.planets;
          if (!_planets.contains(_planet)) {
            _planet = _planets.first;
          }
        });
      }
    } catch (_) {
      // Worker offline — keep default planet list
    }
    await _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final WeatherResult result;
      if (_useEarth) {
        final position = await _getCurrentLocation();
        result = await getEarthWeather(
          position.latitude,
          position.longitude,
        );
      } else {
        result = await getPlanetWeather(_planet, _side);
      }

      if (mounted) {
        setState(() {
          _fullWeatherData = result.data;
          _weatherMeta = result.meta;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weather: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onLocationModeChanged(bool useEarth) {
    if (_useEarth == useEarth) return;
    setState(() => _useEarth = useEarth);
    _loadWeatherData();
  }

  Widget _buildLocationSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Earth')),
              ButtonSegment(value: false, label: Text('Planet')),
            ],
            selected: {_useEarth},
            onSelectionChanged: (set) => _onLocationModeChanged(set.first),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.deepSpace;
                }
                return AppColors.steelBlue;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.brightBlue;
                }
                return AppColors.cardDark.withOpacity(0.6);
              }),
            ),
          ),
          if (!_useEarth) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _planet,
                    dropdownColor: AppColors.cardDark,
                    decoration: InputDecoration(
                      labelText: 'Planet',
                      labelStyle: const TextStyle(color: AppColors.steelBlue),
                      filled: true,
                      fillColor: AppColors.cardDark.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _planets
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: const TextStyle(color: AppColors.pureWhite),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _planet = value);
                      _loadWeatherData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _side,
                    dropdownColor: AppColors.cardDark,
                    decoration: InputDecoration(
                      labelText: 'Side',
                      labelStyle: const TextStyle(color: AppColors.steelBlue),
                      filled: true,
                      fillColor: AppColors.cardDark.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'bright',
                        child: Text('Bright', style: TextStyle(color: AppColors.pureWhite)),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Text('Dark', style: TextStyle(color: AppColors.pureWhite)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _side = value);
                      _loadWeatherData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  String _getFormattedDate() {
    if (_fullWeatherData == null) return '';
    return DateFormat(
      'EEEE, d MMMM yyyy · HH:mm',
    ).format(_fullWeatherData!.currentDate);
  }

  // Temperature color based on value (blue -> red)
  Color _tempColor(double temp) {
    double t = ((temp + 20) / 60).clamp(0.0, 1.0);
    return Color.lerp(Colors.blue, Colors.red, t)!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.deepSpace,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.brightBlue),
              SizedBox(height: 20),
              Text(
                'Fetching weather data...',
                style: TextStyle(color: AppColors.steelBlue),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _fullWeatherData == null) {
      return Scaffold(
        backgroundColor: AppColors.deepSpace,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                _buildLocationSelector(),
                const SizedBox(height: 40),
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Error: $_errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.steelBlue),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Worker: $weatherApiBase',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.dimBlue,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadWeatherData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brightBlue,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final weather = _fullWeatherData!;

    return Scaffold(
      backgroundColor: AppColors.deepSpace,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Status bar (mock)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.mutedBlue,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brightBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '◉ LTE',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.brightBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildLocationSelector(),

              const SizedBox(height: 20),

              // Location
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_weatherMeta != null &&
                        (_weatherMeta!.isSimulated ||
                            _weatherMeta!.note != null))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brightBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _weatherMeta!.isSimulated
                                ? 'Modeled · ${_weatherMeta!.dataSource}'
                                : _weatherMeta!.dataSource,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.lightBlue,
                            ),
                          ),
                        ),
                      ),
                    // Location name with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.pureWhite, Color(0xFFD3E2FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        weather.locationName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.96,
                          height: 1.1,
                          color: AppColors
                              .pureWhite, // will be overridden by gradient
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getFormattedDate(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.16,
                        color: AppColors.steelBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Temperature with gradient and color based on temp
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      _tempColor(weather.temperature),
                      _tempColor(weather.temperature + 5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    '${weather.temperature.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 78,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -4,
                      height: 1.0,
                      color: AppColors.pureWhite, // will be overridden
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Weather condition pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildConditionPill(weather.weatherDescription),
              ),

              const SizedBox(height: 32),

              // Metrics grid
              _buildMetricsGrid(weather),

              const SizedBox(height: 32),

              // Footer (hourly forecast placeholder)
              _buildFooter(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionPill(String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.75),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: AppColors.brightBlue.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002864).withOpacity(0.5),
            offset: const Offset(0, 8),
            blurRadius: 12,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_weatherIcon(description), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.lightBlueWhite,
            ),
          ),
        ],
      ),
    );
  }

  String _weatherIcon(String desc) {
    if (desc.contains('cloud')) return '☁️';
    if (desc.contains('rain')) return '🌧️';
    if (desc.contains('clear')) return '☀️';
    if (desc.contains('snow')) return '❄️';
    if (desc.contains('thunder')) return '⛈️';
    return '☁️';
  }

  Widget _buildMetricsGrid(WeatherData weather) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              // Precipitation card
              Expanded(
                child: _buildMetricCard(
                  label: 'PRECIP',
                  value: '${weather.precipitation.toStringAsFixed(1)}%',
                  subText1: 'no rain',
                  subText2: '0 mm · clear',
                  icon: Icons.water_drop_outlined,
                ),
              ),
              const SizedBox(width: 12),
              // Humidity card
              Expanded(
                child: _buildMetricCard(
                  label: 'HUMIDITY',
                  value: '${weather.humidity.toStringAsFixed(1)}%',
                  subText1: 'dew point 1.2°',
                  hasProgressBar: true,
                  progressValue: weather.humidity / 100,
                  icon: Icons.air,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Wind card (full width)
          _buildWindCard(weather),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    String? subText1,
    String? subText2,
    bool hasProgressBar = false,
    double progressValue = 0.6,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.steelBlue),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                  color: AppColors.steelBlue,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
              color: AppColors.pureWhite,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          if (subText1 != null) ...[
            const SizedBox(height: 4),
            Text(
              subText1,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.steelBlue.withOpacity(0.8),
              ),
            ),
          ],
          if (subText2 != null) ...[
            const SizedBox(height: 2),
            Text(
              subText2,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.steelBlue.withOpacity(0.6),
              ),
            ),
          ],
          if (hasProgressBar) ...[
            const SizedBox(height: 12),
            _buildProgressBar(progressValue),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(double value) {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.electricBlue, AppColors.lightBlue],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindCard(WeatherData weather) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.air, size: 16, color: AppColors.steelBlue),
              const SizedBox(width: 4),
              const Text(
                'WIND',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                  color: AppColors.steelBlue,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                weather.windSpeed.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                  color: AppColors.pureWhite,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'km/h',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: AppColors.steelBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.brightBlue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '⬇️',
                      style: TextStyle(
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: AppColors.brightBlue.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'NNE · 12°',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'gentle breeze · gusts 5.1 km/h', // Replace with actual gusts if available
            style: TextStyle(fontSize: 14, color: AppColors.steelBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.brightBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brightBlue.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'HOURLY FORECAST',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  color: AppColors.dimBlue,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward,
                color: AppColors.dimBlue,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 2,
            width: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.brightBlue,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '▲ ${DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(hours: 6)))}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.deepBlueGray,
                ),
              ),
              Text(
                '▼ ${DateFormat('HH:mm').format(DateTime.now().add(const Duration(hours: 6)))}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.deepBlueGray,
                ),
              ),
              const Text(
                '🌑 waning crescent',
                style: TextStyle(fontSize: 12, color: AppColors.deepBlueGray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
