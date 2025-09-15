import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const WeatherBeatsApp());
}

// Enhanced color palette
const Color kPrimaryColor = Color(0xFF1E1E1E);
const Color kAccentColor = Color(0xFF1DB954);
const Color kTextColor = Color(0xFFFFFFFF);
const Color kCardColor = Color(0xFF2C2C2C);
const Color kErrorColor = Color(0xFFE53935);
const Color kClothingColor = Color(0xFF4CAF50);
const Color kMusicColor = Color(0xFF1DB954);
const Color kWeatherColor = Color(0xFF2196F3);

class WeatherBeatsApp extends StatelessWidget {
  const WeatherBeatsApp({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 👈 add this line
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
  String _weatherDescription = '';
  String _city = '';
  String _selectedMood = 'Calm';
  int _temperature = 0;
  int _feelsLike = 0;
  int _humidity = 0;
  String _tempUnit = 'C'; // C for Celsius, F for Fahrenheit

  // Clothing suggestion data
  Map<String, dynamic> _clothingSuggestions = {};

  late AnimationController _animationController;
  late TabController _tabController;

  final String _backendUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _tabController = TabController(length: 3, vsync: this);
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleTemperatureUnit() {
    setState(() {
      _tempUnit = _tempUnit == 'C' ? 'F' : 'C';
    });
  }

  String _getTemperatureDisplay(int celsius, int fahrenheit) {
    return _tempUnit == 'C' ? '${celsius}°C' : '${fahrenheit}°F';
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

      print('📍 Coordinates: $lat, $lon');
      print('😊 Selected mood: $_selectedMood');

      final response = await http.get(
        Uri.parse(
            '$_backendUrl/api/weather?lat=$lat&lon=$lon&mood=$_selectedMood'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final weatherData = data['weather'] as Map<String, dynamic>?;
        final musicData = data['music'] as Map<String, dynamic>?;
        final clothingData = data['clothing'] as Map<String, dynamic>?;

        if (weatherData != null && musicData != null) {
          setState(() {
            _weatherCondition =
                weatherData['condition']?.toString() ?? 'Unknown';
            _weatherDescription = weatherData['description']?.toString() ?? '';
            _city = weatherData['city']?.toString() ?? 'Unknown City';

            // Temperature data
            final tempData =
                weatherData['temperature'] as Map<String, dynamic>?;
            if (tempData != null) {
              _temperature = tempData['celsius']?.toInt() ?? 0;
              final feelsLikeData =
                  tempData['feelsLike'] as Map<String, dynamic>?;
              if (feelsLikeData != null) {
                _feelsLike = feelsLikeData['celsius']?.toInt() ?? 0;
              }
            }

            _humidity = weatherData['humidity']?.toInt() ?? 0;

            _weatherText = "It's ${_weatherDescription} in $_city!";
            _playlistUrl = musicData['playlistUrl']?.toString() ??
                'https://open.spotify.com/';
            _suggestedGenre =
                musicData['suggestedGenre']?.toString() ?? 'Music';

            // Clothing suggestions
            _clothingSuggestions = clothingData ?? {};

            _errorMessage = '';
          });
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        String errorMsg = 'Failed to load weather data.';
        try {
          final errorData = json.decode(response.body);
          errorMsg = errorData['error']?.toString() ?? errorMsg;
        } catch (e) {
          errorMsg = 'Server returned status ${response.statusCode}';
        }
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
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
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  String _getWeatherAdjective(String condition) {
    if (condition.isEmpty) return 'nice';

    switch (condition.toLowerCase()) {
      case 'clear':
        return 'clear';
      case 'clouds':
        return 'cloudy';
      case 'rain':
        return 'rainy';
      case 'drizzle':
        return 'drizzly';
      case 'thunderstorm':
        return 'stormy';
      case 'snow':
        return 'snowy';
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'hazy';
      default:
        return condition.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading || _errorMessage.isNotEmpty
                      ? _buildStatusContent(context)
                      : _buildMainContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center align
        children: [
          const Text(
            'WeatherBeats',
            style: TextStyle(
              color: kTextColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.music_note, color: kAccentColor, size: 26),
        ],
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
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
          child: _isLoading ? _buildLoadingState() : _buildErrorState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kAccentColor),
            SizedBox(height: 16),
            Text(
              'Fetching weather, music, and clothing suggestions...',
              style: TextStyle(color: kTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _fetchWeatherData,
          style: ElevatedButton.styleFrom(
            backgroundColor: kErrorColor,
          ),
          child: const Text(
            'Try Again',
            style: TextStyle(color: kTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        _buildWeatherSummary(),
        const SizedBox(height: 16),
        _buildMoodSelector(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildWeatherSummary() {
    int tempCelsius = _temperature;
    int tempFahrenheit = (tempCelsius * 9 / 5 + 32).round();
    int feelsLikeCelsius = _feelsLike;
    int feelsLikeFahrenheit = (feelsLikeCelsius * 9 / 5 + 32).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildWeatherIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weatherText,
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTemperatureDisplay(tempCelsius, tempFahrenheit),
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Feels like ${_getTemperatureDisplay(feelsLikeCelsius, feelsLikeFahrenheit)}',
                      style: TextStyle(
                        color: kTextColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail('Humidity', '$_humidity%', Icons.water_drop),
              _buildWeatherDetail('Condition', _weatherCondition, Icons.cloud),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: kTextColor.withOpacity(0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: kTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: kTextColor.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kCardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.mood, color: kAccentColor),
          const SizedBox(width: 12),
          const Text(
            'Mood:',
            style: TextStyle(color: kTextColor, fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMood,
                dropdownColor: kCardColor,
                style: const TextStyle(color: kTextColor),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedMood) {
                    setState(() {
                      _selectedMood = newValue;
                    });
                    _fetchWeatherData();
                  }
                },
                items: [
                  'Happy',
                  'Calm',
                  'Energetic',
                  'Cozy',
                  'Sad',
                  'Anxious',
                  'Tired'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kCardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: kAccentColor,
            labelColor: kTextColor,
            unselectedLabelColor: kTextColor.withOpacity(0.6),
            tabs: const [
              Tab(icon: Icon(Icons.music_note), text: 'Music'),
              Tab(icon: Icon(Icons.checkroom), text: 'Outfit'),
              Tab(icon: Icon(Icons.tips_and_updates), text: 'Tips'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMusicTab(),
                _buildOutfitTab(),
                _buildTipsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Redesigned Music Tab - Compact, no scrolling needed
  Widget _buildMusicTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Compact header with icon and text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_music, size: 30, color: kMusicColor),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perfect for your $_selectedMood mood!',
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_suggestedGenre.isNotEmpty)
                    Text(
                      'Genre: $_suggestedGenre',
                      style: TextStyle(
                        color: kMusicColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Smaller Spotify button
          SizedBox(
            width: 200, // Reduced width
            child: ElevatedButton.icon(
              onPressed: _playlistUrl.isNotEmpty ? _openPlaylist : null,
              icon: const Icon(Icons.play_arrow, color: kTextColor, size: 18),
              label: const Text(
                'Spotify Playlist',
                style: TextStyle(color: kTextColor, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _playlistUrl.isNotEmpty ? kMusicColor : Colors.grey,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                shadowColor: kMusicColor.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Redesigned Outfit Tab - Grid layout, no scrolling
  Widget _buildOutfitTab() {
    final outfit = _clothingSuggestions['outfit'] as List<dynamic>? ?? [];
    final accessories =
        _clothingSuggestions['accessories'] as List<dynamic>? ?? [];
    final footwear = _clothingSuggestions['footwear'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Three sections in a row
          Expanded(
            child: Row(
              children: [
                if (outfit.isNotEmpty)
                  Expanded(child: _buildCompactClothingSection('👕', outfit)),
                if (outfit.isNotEmpty &&
                    (accessories.isNotEmpty || footwear.isNotEmpty))
                  const SizedBox(width: 8),
                if (accessories.isNotEmpty)
                  Expanded(
                      child: _buildCompactClothingSection('🎒', accessories)),
                if (accessories.isNotEmpty && footwear.isNotEmpty)
                  const SizedBox(width: 8),
                if (footwear.isNotEmpty)
                  Expanded(child: _buildCompactClothingSection('👟', footwear)),
              ],
            ),
          ),

          // If no clothing data, show placeholder
          if (outfit.isEmpty && accessories.isEmpty && footwear.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checkroom, size: 48, color: kClothingColor),
                    SizedBox(height: 8),
                    Text(
                      'Outfit suggestions will appear here',
                      style: TextStyle(color: kTextColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

// Redesigned Tips Tab - Compact list, no scrolling
  Widget _buildTipsTab() {
    final tips = _clothingSuggestions['tips'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.lightbulb, size: 24, color: kClothingColor),
              const SizedBox(width: 8),
              const Text(
                'Weather Tips',
                style: TextStyle(
                  color: kTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tips list - takes remaining space
          Expanded(
            child: tips.isNotEmpty
                ? ListView.builder(
                    itemCount:
                        tips.length > 6 ? 6 : tips.length, // Limit to 6 tips
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: const BoxDecoration(
                                color: kClothingColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tips[index].toString(),
                                style: const TextStyle(
                                  color: kTextColor,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tips_and_updates,
                            size: 48, color: kClothingColor),
                        SizedBox(height: 8),
                        Text(
                          'Have a great day!',
                          style: TextStyle(color: kTextColor, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

// Compact clothing section for outfit tab
  Widget _buildCompactClothingSection(String emoji, List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kClothingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kClothingColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with emoji
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 8),

          // Items list
          Expanded(
            child: ListView.builder(
              itemCount:
                  items.length > 4 ? 4 : items.length, // Limit to 4 items
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 4, right: 6),
                        decoration: const BoxDecoration(
                          color: kClothingColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          items[index].toString(),
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 11,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Show "and more" if there are more items
          if (items.length > 4)
            Text(
              '+${items.length - 4} more',
              style: TextStyle(
                color: kClothingColor,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon() {
    final weatherIcon = _getWeatherIcon(_weatherCondition);
    return Icon(weatherIcon, size: 60, color: kTextColor);
  }

  Future<void> _openPlaylist() async {
    if (_playlistUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(_playlistUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Could not launch $_playlistUrl';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Error opening playlist: $e';
        });
      }
    }
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.isEmpty) return Icons.cloud;

    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.cloudy_snowing;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
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
