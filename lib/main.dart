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

class _WeatherBeatsHomePageState extends State<WeatherBeatsHomePage> {
  // Store the fetched data and UI state
  String _weatherText = 'Fetching weather...';
  String _playlistUrl = '';
  bool _isLoading = true;
  String _errorMessage = '';

  // Placeholder for your backend URL
  // Replace with the URL of your Node.js server
  final String _backendUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get the current location
      Position position = await _determinePosition();
      final lat = position.latitude;
      final lon = position.longitude;

      // Make a request to your backend server
      final response = await http.get(
        Uri.parse('$_backendUrl/api/weather?lat=$lat&lon=$lon'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherText =
              '${data['weather']['condition']} in ${data['weather']['city']}';
          _playlistUrl = data['music']['playlistUrl'];
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
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Main content card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: kCardColor,
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
                    Text(
                      'Your Daily Vibe',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: kTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const CircularProgressIndicator(color: kAccentColor)
                    else if (_errorMessage.isNotEmpty)
                      Column(
                        children: [
                          const Icon(Icons.error, color: kErrorColor, size: 50),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(color: kErrorColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Text(
                            _weatherText,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: kTextColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your playlist for today:',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: kAccentColor),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getGenreFromUrl(_playlistUrl),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _openPlaylist,
                            icon: const Icon(
                              Icons.music_note,
                              color: kTextColor,
                            ),
                            label: const Text(
                              'Open on Spotify',
                              style: TextStyle(color: kTextColor),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Refresh button
              ElevatedButton.icon(
                onPressed: _fetchWeatherData,
                icon: const Icon(Icons.refresh, color: kPrimaryColor),
                label: const Text(
                  'Refresh',
                  style: TextStyle(color: kPrimaryColor),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGenreFromUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.parse(url);
    final queryParameter = uri.pathSegments.last;
    return queryParameter.replaceAll('+', ' ');
  }

  Future<void> _openPlaylist() async {
    if (_playlistUrl.isNotEmpty) {
      final uri = Uri.parse(_playlistUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        setState(() {
          _errorMessage = 'Could not launch $_playlistUrl';
        });
      }
    }
  }
}
