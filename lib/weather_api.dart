import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

typedef WeatherData = ({
  double temperature,
  double feelsLike,
  double humidity,
  String weatherDescription,
  double precipitation,
  double windSpeed,
  String locationName,
  DateTime currentDate,
});

class WeatherMeta {
  const WeatherMeta({
    required this.dataSource,
    required this.isSimulated,
    this.note,
  });

  final String dataSource;
  final bool isSimulated;
  final String? note;
}

class WeatherResult {
  const WeatherResult({required this.data, required this.meta});

  final WeatherData data;
  final WeatherMeta meta;
}

String get weatherApiBase =>
    dotenv.env['WEATHER_API_URL']?.trim() ?? 'http://127.0.0.1:8787';

WeatherData _parseWeatherData(Map<String, dynamic> data) {
  return (
    temperature: (data['temperature'] as num).toDouble(),
    feelsLike: (data['feelsLike'] as num).toDouble(),
    humidity: (data['humidity'] as num).toDouble(),
    weatherDescription: data['weatherDescription'] as String,
    precipitation: (data['precipitation'] as num).toDouble(),
    windSpeed: (data['windSpeed'] as num).toDouble(),
    locationName: data['locationName'] as String,
    currentDate: DateTime.parse(data['currentDate'] as String),
  );
}

WeatherMeta _parseMeta(Map<String, dynamic> data) {
  final meta = data['meta'] as Map<String, dynamic>? ?? {};
  return WeatherMeta(
    dataSource: meta['dataSource'] as String? ?? 'unknown',
    isSimulated: meta['isSimulated'] as bool? ?? false,
    note: meta['note'] as String?,
  );
}

Future<WeatherResult> _fetchWeather(Uri url) async {
  final response = await http.get(url);
  if (response.statusCode != 200) {
    final body = response.body;
    try {
      final err = json.decode(body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Failed to load weather');
    } catch (_) {
      throw Exception('Failed to load weather ($body)');
    }
  }

  final data = json.decode(response.body) as Map<String, dynamic>;
  return WeatherResult(data: _parseWeatherData(data), meta: _parseMeta(data));
}

Future<WeatherResult> getEarthWeather(double lat, double lon) {
  final url = Uri.parse('$weatherApiBase/v1/weather?lat=$lat&lon=$lon');
  return _fetchWeather(url);
}

Future<WeatherResult> getPlanetWeather(String planet, String side) {
  final url = Uri.parse(
    '$weatherApiBase/v1/weather?planet=${Uri.encodeComponent(planet)}&side=${Uri.encodeComponent(side)}',
  );
  return _fetchWeather(url);
}

Future<({List<String> planets, List<String> sides})> fetchSupportedPlanets() async {
  final response = await http.get(Uri.parse('$weatherApiBase/v1/planets'));
  if (response.statusCode != 200) {
    return (
      planets: ['mars', 'moon', 'venus', 'mercury', 'jupiter'],
      sides: ['bright', 'dark'],
    );
  }
  final data = json.decode(response.body) as Map<String, dynamic>;
  return (
    planets: (data['planets'] as List<dynamic>).cast<String>(),
    sides: (data['sides'] as List<dynamic>).cast<String>(),
  );
}
