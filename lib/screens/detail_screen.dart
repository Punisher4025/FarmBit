import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/crop_model.dart';
import '../models/mandi_model.dart';
import '../services/crop_price_predictor.dart';
import '../services/localization_service.dart';
import '../services/mandi_service.dart';

class DetailScreen extends StatefulWidget {
  final Crop crop;
  final double currentTemp;
  final double currentRain;
  final double currentHum;
  final String cityName;
  final Mandi selectedMandi;

  const DetailScreen({
    super.key,
    required this.crop,
    required this.currentTemp,
    required this.currentRain,
    required this.currentHum,
    required this.cityName,
    required this.selectedMandi,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Slider states initialized with passed weather values
  late double _simulatedTemp;
  late double _simulatedRain;
  late double _simulatedHum;
  late int _simulatedMonth;
  late double _predictedPrice;

  // Forecast scenario tab state
  String _currentScenario = 'normal'; // 'normal', 'drought', 'flood'

  @override
  void initState() {
    super.initState();
    _simulatedTemp = widget.currentTemp;
    _simulatedRain = widget.currentRain;
    _simulatedHum = widget.currentHum;
    _simulatedMonth = DateTime.now().month;
    _updatePrediction();
  }

  void _updatePrediction() {
    final rawMLPrice = CropPricePredictor.predict(
      cropIndex: widget.crop.id,
      month: _simulatedMonth,
      temperature: _simulatedTemp,
      rainfall: _simulatedRain,
      humidity: _simulatedHum,
    );
    // Anchor predictions to selected mandi modifier
    _predictedPrice = rawMLPrice * MandiService.getMandiPriceModifier(widget.selectedMandi, widget.crop.id);
  }

  // Estimate weather for a given month to draw the seasonal forecast chart
  double _estimateTempForMonth(int m) {
    // Standard seasonal curve (peaking in month 6/7, cold in 12/1)
    // Delhi-like temperature curve model:
    // Simulate deviation around the optimal or standard climate
    return 15.0 + 18.0 * (0.5 - 0.5 * (3.14159 * (m - 6) / 6).clamp(-1, 1));
  }

  double _estimateRainForMonth(int m) {
    // Monsoon peaks in July (7) and Aug (8)
    if (m == 7 || m == 8) return 220.0;
    if (m == 6 || m == 9) return 120.0;
    if (m == 5 || m == 10) return 40.0;
    return 15.0;
  }

  double _estimateHumForMonth(int m) {
    if (m >= 7 && m <= 9) return 80.0;
    if (m >= 11 || m <= 2) return 55.0;
    return 45.0;
  }

  List<FlSpot> _generateForecastSpots() {
    List<FlSpot> spots = [];
    final currentM = DateTime.now().month;
    final mandiModifier = MandiService.getMandiPriceModifier(widget.selectedMandi, widget.crop.id);

    for (int i = 0; i < 6; i++) {
      int targetMonth = ((currentM + i - 1) % 12) + 1;
      double temp = _estimateTempForMonth(targetMonth);
      double rain = _estimateRainForMonth(targetMonth);
      double hum = _estimateHumForMonth(targetMonth);
      
      // Inject scenario modifications into the future months
      if (_currentScenario == 'drought') {
        temp += 4.5;
        rain = (rain * 0.15).clamp(5.0, 30.0);
        hum = (hum * 0.6).clamp(25.0, 45.0);
      } else if (_currentScenario == 'flood') {
        temp -= 1.5;
        rain = (rain * 2.5).clamp(200.0, 500.0);
        hum = (hum * 1.3).clamp(80.0, 100.0);
      }

      double price = CropPricePredictor.predict(
        cropIndex: widget.crop.id,
        month: targetMonth,
        temperature: temp,
        rainfall: rain,
        humidity: hum,
      );
      
      // Anchor prediction to selected mandi
      price *= mandiModifier;
      
      spots.add(FlSpot(i.toDouble(), price));
    }
    return spots;
  }

  String _getMonthName(int monthNum) {
    const keys = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    return LocalizationService.translate(keys[monthNum - 1]);
  }

  String _getInsightText() {
    double tempDiff = (_simulatedTemp - widget.crop.optimalTemp).abs();
    double rainDiff = (_simulatedRain - widget.crop.optimalRain).abs();
    
    if (tempDiff > 10.0 && _simulatedRain < 30.0) {
      return LocalizationService.translate('insight_drought');
    } else if (_simulatedRain > 2.5 * widget.crop.optimalRain) {
      return LocalizationService.translate('insight_flood');
    } else if (tempDiff <= 4.0 && rainDiff <= 40.0) {
      return LocalizationService.translate('insight_ideal');
    } else {
      return LocalizationService.translate('insight_stable');
    }
  }

  @override

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLanguage,
      builder: (context, lang, child) {
        final spots = _generateForecastSpots();
        final currentM = DateTime.now().month;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Stack(
            children: [
              // Background Gradient Blob
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.crop.color.withOpacity(0.12),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                    child: Container(),
                  ),
                ),
              ),
              
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              LocalizationService.translate('model_analyzer'),
                              style: GoogleFonts.outfit(
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E293B),
                                    title: Text('${LocalizationService.translate('about_title')} (${widget.crop.name})', style: const TextStyle(color: Colors.white)),
                                    content: Text(
                                      LocalizationService.translate('about_desc'),
                                      style: const TextStyle(color: Colors.blueGrey, height: 1.4),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(LocalizationService.translate('got_it'), style: const TextStyle(color: Colors.teal)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Interactive Simulation Panel
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E293B).withOpacity(0.8),
                                const Color(0xFF0F172A).withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.blueGrey.shade700.withOpacity(0.8)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Crop Icon & Name
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: widget.crop.color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(widget.crop.icon, color: widget.crop.color, size: 36),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.crop.name,
                                          style: GoogleFonts.outfit(
                                            textStyle: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          widget.crop.category,
                                          style: TextStyle(
                                            color: Colors.blueGrey.shade400,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              // Price Meter
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      LocalizationService.translate('predicted_market_price'),
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade400,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '₹${_predictedPrice.toStringAsFixed(2)}',
                                          style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: widget.crop.color,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ' / ${LocalizationService.translate('per_kg')}',
                                          style: TextStyle(
                                            color: Colors.blueGrey.shade400,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(color: Colors.white10),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStaticMetric(
                                          label: LocalizationService.translate('current_mandi_price'),
                                          value: '₹${MandiService.getCurrentMandiPrice(widget.selectedMandi, widget.crop, _simulatedTemp, _simulatedRain, _simulatedHum, _simulatedMonth).toStringAsFixed(1)}',
                                        ),
                                        _buildStaticMetric(
                                          label: LocalizationService.translate('location'),
                                          value: widget.cityName,
                                        ),
                                        _buildStaticMetric(
                                          label: LocalizationService.translate('simulated_month'),
                                          value: _getMonthName(_simulatedMonth),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Simulators Section
                              Row(
                                children: [
                                  const Icon(Icons.tune, color: Colors.teal, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    LocalizationService.translate('weather_simulator'),
                                    style: GoogleFonts.outfit(
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Simulators
                              _buildSlider(
                                value: _simulatedTemp,
                                min: 0.0,
                                max: 50.0,
                                label: LocalizationService.translate('temperature_label'),
                                suffix: '°C',
                                color: Colors.orange,
                                onChanged: (val) {
                                  setState(() {
                                    _simulatedTemp = val;
                                    _updatePrediction();
                                  });
                                },
                              ),
                              _buildSlider(
                                value: _simulatedRain,
                                min: 0.0,
                                max: 300.0,
                                label: LocalizationService.translate('rainfall_label'),
                                suffix: ' mm',
                                color: Colors.blue,
                                onChanged: (val) {
                                  setState(() {
                                    _simulatedRain = val;
                                    _updatePrediction();
                                  });
                                },
                              ),
                              _buildSlider(
                                value: _simulatedHum,
                                min: 10.0,
                                max: 100.0,
                                label: LocalizationService.translate('humidity_label'),
                                suffix: '%',
                                color: Colors.teal,
                                onChanged: (val) {
                                  setState(() {
                                    _simulatedHum = val;
                                    _updatePrediction();
                                  });
                                },
                              ),
                              _buildSlider(
                                value: _simulatedMonth.toDouble(),
                                min: 1.0,
                                max: 12.0,
                                label: LocalizationService.translate('prediction_month_label'),
                                suffix: '',
                                color: Colors.purple,
                                divisions: 11,
                                customValueText: _getMonthName(_simulatedMonth),
                                onChanged: (val) {
                                  setState(() {
                                    _simulatedMonth = val.round();
                                    _updatePrediction();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                                            // Weather Insight Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade900.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blueGrey.shade800),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _getInsightText(),
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 6-Month Seasonal Price Forecast Chart
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Text(
                          LocalizationService.translate('six_month_forecast'),
                          style: GoogleFonts.outfit(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Scenario tabs
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _buildScenarioTab('normal', Icons.wb_sunny_outlined, LocalizationService.translate('scenario_normal')),
                            const SizedBox(width: 8),
                            _buildScenarioTab('drought', Icons.sunny, LocalizationService.translate('scenario_drought')),
                            const SizedBox(width: 8),
                            _buildScenarioTab('flood', Icons.thunderstorm_outlined, LocalizationService.translate('scenario_flood')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Forecast chart card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 220,
                          padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.blueGrey.shade800),
                          ),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withOpacity(0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      int m = (currentM + value.toInt() - 1) % 12 + 1;
                                      if (m == 0) m = 12;
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          _getMonthName(m).substring(0, 3),
                                          style: const TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 10,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '₹${value.toInt()}',
                                        style: const TextStyle(color: Colors.blueGrey, fontSize: 9, fontWeight: FontWeight.bold),
                                      );
                                    },
                                    reservedSize: 32,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 5,
                              minY: 10,
                              maxY: 90,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: widget.crop.color,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: widget.crop.color.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Reasons Panel
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Text(
                          LocalizationService.translate('reasons_analysis'),
                          style: GoogleFonts.outfit(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            ...MandiService.getPredictionReasons(
                              mandi: widget.selectedMandi,
                              crop: widget.crop,
                              temp: _simulatedTemp,
                              rain: _simulatedRain,
                              hum: _simulatedHum,
                              month: _simulatedMonth,
                            ).map((reason) => _buildReasonCard(reason)),
                          ],
                        ),
                      ),

                      // Crop description & cultivation benefits cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.blueGrey.shade800),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.translate('crop_desc'),
                                style: GoogleFonts.outfit(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.crop.description,
                                style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                LocalizationService.translate('key_benefits'),
                                style: GoogleFonts.outfit(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.crop.benefits,
                                style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildStaticMetric({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10),
        ),
        const SizedBox(height: 4),
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
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required Color color,
    int? divisions,
    String? customValueText,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              customValueText ?? '${value.toStringAsFixed(1)}$suffix',
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioTab(String scenarioId, IconData icon, String label) {
    final isActive = _currentScenario == scenarioId;
    final activeColor = scenarioId == 'drought' ? Colors.orange : (scenarioId == 'flood' ? Colors.blue : Colors.teal);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentScenario = scenarioId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeColor.withOpacity(0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? activeColor : Colors.blueGrey, size: 14),
              const SizedBox(width: 4),
              Text(
                label.split(' ')[0], // short first word
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.blueGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonCard(MandiPriceReason reason) {
    final isIncrease = reason.impact == 'positive';
    final isNeutral = reason.impact == 'neutral';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.shade800.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: reason.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(reason.icon, color: reason.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason.title,
                  style: GoogleFonts.outfit(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason.description,
                  style: TextStyle(
                    color: Colors.blueGrey.shade300,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (!isNeutral)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reason.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: reason.color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    color: reason.color,
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    reason.valueText,
                    style: TextStyle(
                      color: reason.color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
