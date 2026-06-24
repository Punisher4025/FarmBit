import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/crop_model.dart';
import '../models/mandi_model.dart';
import '../services/weather_service.dart';
import '../services/crop_price_predictor.dart';
import '../services/localization_service.dart';
import '../services/mandi_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isSearching = false;
  WeatherData? _weatherData;
  List<Map<String, dynamic>> _searchResults = [];
  String _lastSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Default location: New Delhi, India
  String _currentCity = "New Delhi";
  String _currentRegion = "Delhi";
  double _currentLat = 28.6139;
  double _currentLon = 77.2090;

  // Mandi variables
  List<Mandi> _availableMandis = [];
  Mandi? _selectedMandi;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final weather = await WeatherService.fetchWeather(
        latitude: _currentLat,
        longitude: _currentLon,
        cityName: _currentCity,
        region: _currentRegion,
      );
      
      final mandis = MandiService.getMandisForState(weather.region);
      
      setState(() {
        _weatherData = weather;
        _availableMandis = mandis;
        _selectedMandi = mandis.isNotEmpty ? mandis.first : MandiService.defaultMandi;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading weather data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _lastSearchQuery = '';
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _lastSearchQuery = trimmed;
    });
    try {
      final results = await WeatherService.searchLocation(trimmed);
      // Only update if the query hasn't changed while we were fetching
      if (_lastSearchQuery == trimmed) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _currentCity = location['name'];
      _currentRegion = location['region'];
      _currentLat = location['latitude'];
      _currentLon = location['longitude'];
      _searchResults = [];
      _searchController.clear();
    });
    _loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLanguage,
      builder: (context, lang, child) {
        final currentMonth = DateTime.now().month;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Slate 900
          body: Stack(
            children: [
              // Background Gradient Blobs
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.withOpacity(0.15),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withOpacity(0.1),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: Container(),
                  ),
                ),
              ),
              
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header / App Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationService.translate('app_title'),
                                  style: GoogleFonts.outfit(
                                    textStyle: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  LocalizationService.translate('app_subtitle'),
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                DropdownButton<String>(
                                  value: LocalizationService.currentLanguage.value,
                                  dropdownColor: const Color(0xFF1E293B),
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.language, color: Colors.teal),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  items: LocalizationService.languages.entries.map((entry) {
                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value.split(' ')[0]),
                                    );
                                  }).toList(),
                                  onChanged: (String? val) {
                                    if (val != null) {
                                      LocalizationService.changeLanguage(val);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.teal.withOpacity(0.2)),
                                  ),
                                  child: const Icon(
                                    Icons.psychology,
                                    color: Colors.teal,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Location Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B), // Slate 800
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blueGrey.shade700),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: LocalizationService.translate('search_hint'),
                                  hintStyle: TextStyle(color: Colors.blueGrey.shade500),
                                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            // Search loading spinner
                            if (_isSearching)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blueGrey.shade700),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Searching...', style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              )
                            // Search results list
                            else if (_searchResults.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blueGrey.shade700),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final loc = _searchResults[index];
                                    return ListTile(
                                      leading: const Icon(Icons.location_on, color: Colors.teal),
                                      title: Text(
                                        '${loc['name']}, ${loc['region']}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        '${loc['country']} (${loc['latitude'].toStringAsFixed(2)}, ${loc['longitude'].toStringAsFixed(2)})',
                                        style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                                      ),
                                      onTap: () => _selectLocation(loc),
                                    );
                                  },
                                ),
                              )
                            // No results state
                            else if (_lastSearchQuery.isNotEmpty && !_isSearching)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blueGrey.shade700),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, color: Colors.blueGrey.shade500, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'No results for "$_lastSearchQuery"',
                                      style: TextStyle(color: Colors.blueGrey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Weather Card (Simulating local weather API / mock)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: _buildWeatherCard(),
                      ),
                    ),

                    // Mandi Selector Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildMandiSelectorCard(),
                      ),
                    ),

                    // Section Title: Crops
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(
                          LocalizationService.translate('prediction_title'),
                          style: GoogleFonts.outfit(
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Grid of Crops
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.82,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final crop = Crop.allCrops[index];
                            final temp = _weatherData?.temperature ?? 25.0;
                            final rain = _weatherData?.rainfall ?? 50.0;
                            final hum = _weatherData?.humidity ?? 60.0;

                            final currentMandiPrice = _selectedMandi != null
                                ? MandiService.getCurrentMandiPrice(
                                    _selectedMandi!,
                                    crop,
                                    temp,
                                    rain,
                                    hum,
                                    currentMonth,
                                  )
                                : crop.basePrice;

                            // Predict price
                            final predictedPrice = CropPricePredictor.predict(
                              cropIndex: crop.id,
                              month: currentMonth,
                              temperature: temp,
                              rainfall: rain,
                              humidity: hum,
                            );

                            final priceDiffPercent = ((predictedPrice - currentMandiPrice) / currentMandiPrice) * 100;
                            final isPositive = priceDiffPercent >= 0;

                            return _buildCropCard(
                              crop,
                              predictedPrice,
                              currentMandiPrice,
                              priceDiffPercent,
                              isPositive,
                              temp,
                              rain,
                              hum,
                            );
                          },
                          childCount: Crop.allCrops.length,
                        ),
                      ),
                    ),

                    // Bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherCard() {
    if (_isLoading) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueGrey.shade700),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    final weather = _weatherData;
    if (weather == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withOpacity(0.8),
            const Color(0xFF0F172A).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade700.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${weather.cityName}, ${weather.region}',
                          style: GoogleFonts.outfit(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature.toStringAsFixed(1)}°C',
                          style: GoogleFonts.outfit(
                            textStyle: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          LocalizationService.translate('current_temp'),
                          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                    _buildWeatherMetric(
                      icon: Icons.water_drop,
                      value: '${weather.humidity.toStringAsFixed(0)}%',
                      label: LocalizationService.translate('humidity'),
                      color: Colors.blue,
                    ),
                    _buildWeatherMetric(
                      icon: Icons.umbrella,
                      value: '${weather.rainfall.toStringAsFixed(1)} mm',
                      label: LocalizationService.translate('rainfall'),
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildMandiSelectorCard() {
    if (_isLoading) return const SizedBox.shrink();
    if (_weatherData == null || _availableMandis.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade700.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService.translate('mandi_selector'),
                    style: GoogleFonts.outfit(
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<Mandi>(
                      value: _selectedMandi,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      onChanged: (Mandi? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMandi = newValue;
                          });
                        }
                      },
                      items: _availableMandis.map<DropdownMenuItem<Mandi>>((Mandi mandi) {
                        return DropdownMenuItem<Mandi>(
                          value: mandi,
                          child: Text(mandi.name),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_selectedMandi?.volumeStatus == 'High' ? Colors.green : Colors.blue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_selectedMandi?.volumeStatus == 'High' ? Colors.green : Colors.blue).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _selectedMandi?.volumeStatus == 'High' ? 'High Volume' : 'Medium Vol',
                    style: TextStyle(
                      color: _selectedMandi?.volumeStatus == 'High' ? Colors.green : Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedMandi?.district ?? '',
                  style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCard(
    Crop crop,
    double predictedPrice,
    double currentMandiPrice,
    double priceDiffPercent,
    bool isPositive,
    double currentTemp,
    double currentRain,
    double currentHum,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              crop: crop,
              currentTemp: currentTemp,
              currentRain: currentRain,
              currentHum: currentHum,
              cityName: _currentCity,
              selectedMandi: _selectedMandi ?? MandiService.defaultMandi,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueGrey.shade700.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: crop.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(crop.icon, color: crop.color, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.teal : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isPositive ? Colors.teal : Colors.red,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${priceDiffPercent.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.teal : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                crop.name,
                style: GoogleFonts.outfit(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                crop.category,
                style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mandi: ₹${currentMandiPrice.toStringAsFixed(1)}',
                        style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹${predictedPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        LocalizationService.translate('predicted_kg'),
                        style: const TextStyle(color: Colors.teal, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.blueGrey,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
