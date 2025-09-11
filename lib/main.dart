import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const WeatherBeatsApp());
}

// A simple color palette for a clean look
const Color kPrimaryColor = Color(0xFF1E1E1E);
const Color kAccentColor = Color(0xFF1DB954);
const Color kTextColor = Color(0xFFFFFFFF);
const Color kCardColor = Color(0xFF2C2C2C);
const Color kErrorColor = Color(0xFFE53935);

class WeatherBeatsApp extends StatelessWidget {
  const WeatherBeatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherBeats',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kPrimaryColor,
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryColor,
          secondary: kAccentColor,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const WeatherBeatsHomePage(),
    );
  }
}

class WeatherBeatsHomePage extends StatefulWidget {
  const WeatherBeatsHomePage({super.key});

  @override
  State<WeatherBeatsHomePage> createState() => _WeatherBeatsHomePageState();
}

class _WeatherBeatsHomePageState extends State<WeatherBeatsHomePage>
    with TickerProviderStateMixin {
  String _weatherText = 'Fetching weather...';
  String _playlistUrl = '';
  String _suggestedGenre = '';
  bool _isLoading = true;
  String _errorMessage = '';
  String _weatherCondition = '';
  String _city = '';
  String _selectedMood = 'Calm'; // New state variable for mood

  late AnimationController _animationController;

  final String _backendUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Position position = await _determinePosition();
      final lat = position.latitude;
      final lon = position.longitude;

      final response = await http.get(
        Uri.parse(
            '$_backendUrl/api/weather?lat=$lat&lon=$lon&mood=$_selectedMood'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherCondition = data['weather']['condition'];
          _city = data['weather']['city'];
          _weatherText =
              "Hey, it's ${_weatherCondition.toLowerCase()} today in $_city!";
          _playlistUrl = data['music']['playlistUrl'];
          _suggestedGenre = data['music']['suggestedGenre'];
        });
      } else {
        final errorData = json.decode(response.body);
        _errorMessage = errorData['error'] ?? 'Failed to load weather data.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildContentCard(context),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchWeatherData,
                    icon: const Icon(Icons.refresh, color: kPrimaryColor),
                    label: const Text('Refresh',
                        style: TextStyle(color: kPrimaryColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTextColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: kCardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isLoading || _errorMessage.isNotEmpty)
            _buildStatusContent(context)
          else
            _buildSuccessContent(context),
        ],
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: kAccentColor),
        ),
      );
    } else {
      return _buildErrorState();
    }
  }

  Widget _buildSuccessContent(BuildContext context) {
    final weatherIcon = _getWeatherIcon(_weatherCondition);
    final moods = ['Happy', 'Calm', 'Energetic', 'Cozy'];

    return Column(
      children: [
        Icon(weatherIcon, size: 80, color: kTextColor),
        const SizedBox(height: 20),
        Text(
          "Hey, it's ${_weatherCondition.toLowerCase()} today in $_city!",
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: kTextColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        DropdownButton<String>(
          value: _selectedMood,
          icon: const Icon(Icons.mood, color: kAccentColor),
          dropdownColor: kCardColor,
          style: const TextStyle(color: kTextColor),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedMood = newValue;
              });
              _fetchWeatherData();
            }
          },
          items: moods.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _openPlaylist,
          icon: const Icon(Icons.music_note, color: kTextColor),
          label: const Text('Check out this playlist',
              style: TextStyle(color: kTextColor)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccentColor,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(Icons.error, color: kErrorColor, size: 50),
        const SizedBox(height: 10),
        Text(
          _errorMessage,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: kErrorColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _openPlaylist() async {
    if (_playlistUrl.isNotEmpty) {
      final uri = Uri.parse(_playlistUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Could not launch $_playlistUrl';
        });
      }
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'Clear':
        return Icons.wb_sunny;
      case 'Clouds':
        return Icons.cloud;
      case 'Rain':
        return Icons.cloudy_snowing;
      case 'Drizzle':
        return Icons.grain;
      case 'Thunderstorm':
        return Icons.thunderstorm;
      case 'Snow':
        return Icons.ac_unit;
      case 'Mist':
      case 'Smoke':
      case 'Haze':
      case 'Dust':
      case 'Fog':
        return Icons.blur_on;
      default:
        return Icons.cloud;
    }
  }

  Widget _buildAnimatedBackground() {
    final Map<String, List<Color>> weatherGradients = {
      'Clear': [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
      'Clouds': [const Color(0xFFBDBDBD), const Color(0xFF616161)],
      'Rain': [const Color(0xFF373B44), const Color(0xFF4286f4)],
      'Drizzle': [const Color(0xFF373B44), const Color(0xFF4286f4)],
      'Thunderstorm': [const Color(0xFF232526), const Color(0xFF414345)],
      'Snow': [const Color(0xFFE6DADA), const Color(0xFF274046)],
      'Mist': [const Color(0xFFB2FEFA), const Color(0xFF0ED2F7)],
      'Smoke': [const Color(0xFF606c88), const Color(0xFF3f4c6b)],
      'Haze': [
        const Color(0xFF8a2387),
        const Color(0xFFe94057),
        const Color(0xFFf27121)
      ],
      'Dust': [const Color(0xFF6B431E), const Color(0xFFD3A97D)],
      'Fog': [const Color(0xFF4F4F4F), const Color(0xFF2C3E50)],
      'default': [kPrimaryColor, const Color(0xFF434343)],
    };

    final gradientColors =
        weatherGradients[_weatherCondition] ?? weatherGradients['default']!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(gradientColors[0], gradientColors[1],
                    _animationController.value)!,
                Color.lerp(gradientColors[1], gradientColors[0],
                    _animationController.value)!,
              ],
            ),
          ),
        );
      },
    );
  }
}
