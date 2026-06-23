import 'package:flutter/material.dart';
import '../models/mandi_model.dart';
import '../models/crop_model.dart';
import 'localization_service.dart';

class MandiPriceReason {
  final String title;
  final String description;
  final String impact; // 'positive' (drives price up), 'negative' (drives price down), 'neutral'
  final String valueText;
  final IconData icon;
  final Color color;

  MandiPriceReason({
    required this.title,
    required this.description,
    required this.impact,
    required this.valueText,
    required this.icon,
    required this.color,
  });
}

class MandiService {
  static final List<Mandi> _allMandis = [
    // Delhi
    Mandi(id: 'del_azadpur', name: 'Azadpur Mandi', state: 'Delhi', district: 'North Delhi', volumeStatus: 'High'),
    Mandi(id: 'del_okhla', name: 'Okhla Mandi', state: 'Delhi', district: 'South Delhi', volumeStatus: 'Medium'),
    Mandi(id: 'del_narela', name: 'Narela Mandi', state: 'Delhi', district: 'North West Delhi', volumeStatus: 'Medium'),
    
    // Punjab
    Mandi(id: 'pb_khanna', name: 'Khanna Mandi', state: 'Punjab', district: 'Ludhiana', volumeStatus: 'High'),
    Mandi(id: 'pb_ludhiana', name: 'Ludhiana Mandi', state: 'Punjab', district: 'Ludhiana', volumeStatus: 'Medium'),
    Mandi(id: 'pb_jalandhar', name: 'Jalandhar Mandi', state: 'Punjab', district: 'Jalandhar', volumeStatus: 'Medium'),
    Mandi(id: 'pb_amritsar', name: 'Amritsar Mandi', state: 'Punjab', district: 'Amritsar', volumeStatus: 'Medium'),

    // Haryana
    Mandi(id: 'hr_karnal', name: 'Karnal Mandi', state: 'Haryana', district: 'Karnal', volumeStatus: 'High'),
    Mandi(id: 'hr_ambala', name: 'Ambala Mandi', state: 'Haryana', district: 'Ambala', volumeStatus: 'Medium'),
    Mandi(id: 'hr_rohtak', name: 'Rohtak Mandi', state: 'Haryana', district: 'Rohtak', volumeStatus: 'Medium'),
    
    // Maharashtra
    Mandi(id: 'mh_lasalgaon', name: 'Lasalgaon Mandi', state: 'Maharashtra', district: 'Nashik', volumeStatus: 'High'),
    Mandi(id: 'mh_pune', name: 'Pune Mandi', state: 'Maharashtra', district: 'Pune', volumeStatus: 'High'),
    Mandi(id: 'mh_nagpur', name: 'Nagpur Mandi', state: 'Maharashtra', district: 'Nagpur', volumeStatus: 'Medium'),
    Mandi(id: 'mh_mumbai', name: 'Vashi Mandi (Mumbai)', state: 'Maharashtra', district: 'Thane', volumeStatus: 'High'),

    // Uttar Pradesh
    Mandi(id: 'up_lucknow', name: 'Lucknow Mandi', state: 'Uttar Pradesh', district: 'Lucknow', volumeStatus: 'Medium'),
    Mandi(id: 'up_agra', name: 'Agra Mandi', state: 'Uttar Pradesh', district: 'Agra', volumeStatus: 'High'),
    Mandi(id: 'up_hapur', name: 'Hapur Mandi', state: 'Uttar Pradesh', district: 'Hapur', volumeStatus: 'Medium'),
    Mandi(id: 'up_kanpur', name: 'Kanpur Mandi', state: 'Uttar Pradesh', district: 'Kanpur', volumeStatus: 'High'),

    // Karnataka
    Mandi(id: 'ka_yeshwanthpur', name: 'Yeshwanthpur Mandi', state: 'Karnataka', district: 'Bangalore Urban', volumeStatus: 'High'),
    Mandi(id: 'ka_hubli', name: 'Hubli Mandi', state: 'Karnataka', district: 'Dharwad', volumeStatus: 'Medium'),
    Mandi(id: 'ka_mysore', name: 'Mysore Mandi', state: 'Karnataka', district: 'Mysore', volumeStatus: 'Medium'),

    // Rajasthan
    Mandi(id: 'rj_jaipur', name: 'Jaipur Mandi', state: 'Rajasthan', district: 'Jaipur', volumeStatus: 'High'),
    Mandi(id: 'rj_sriganganagar', name: 'Sri Ganganagar Mandi', state: 'Rajasthan', district: 'Sri Ganganagar', volumeStatus: 'Medium'),

    // Madhya Pradesh
    Mandi(id: 'mp_indore', name: 'Indore Mandi', state: 'Madhya Pradesh', district: 'Indore', volumeStatus: 'High'),
    Mandi(id: 'mp_bhopal', name: 'Bhopal Mandi', state: 'Madhya Pradesh', district: 'Bhopal', volumeStatus: 'Medium'),
  ];

  // Default national mandi
  static final Mandi defaultMandi = Mandi(
    id: 'national_avg',
    name: 'National Average Mandi',
    state: 'Delhi',
    district: 'National',
    volumeStatus: 'High',
  );

  /// Get mandis for a specific state. Fallback to Delhi if state not found/supported.
  static List<Mandi> getMandisForState(String stateName) {
    final normalizedSearch = stateName.trim().toLowerCase();
    
    // Find matching state
    final matchedMandis = _allMandis.where((mandi) {
      return mandi.state.toLowerCase() == normalizedSearch ||
             normalizedSearch.contains(mandi.state.toLowerCase()) ||
             mandi.state.toLowerCase().contains(normalizedSearch);
    }).toList();

    if (matchedMandis.isNotEmpty) {
      return matchedMandis;
    }

    // Default return all Delhi mandis if state has no matched mandis
    return _allMandis.where((m) => m.state == 'Delhi').toList();
  }

  /// Returns mandi specific multiplier for each crop type based on regional factors
  static double getMandiPriceModifier(Mandi mandi, int cropId) {
    // 0: Wheat, 1: Rice, 2: Maize, 3: Cotton, 4: Potato, 5: Tomato, 6: Onion, 7: Sugarcane
    switch (mandi.id) {
      // Punjab (Khanna, Ludhiana) has surplus Wheat & Rice -> lower prices
      case 'pb_khanna':
      case 'pb_ludhiana':
        if (cropId == 0 || cropId == 1) return 0.90;
        if (cropId == 3) return 1.05; // Cotton is higher
        return 1.0;
      
      // Haryana (Karnal) has high Rice surplus -> cheaper rice
      case 'hr_karnal':
        if (cropId == 1) return 0.92;
        if (cropId == 0) return 0.95;
        return 1.0;

      // Lasalgaon Maharashtra is Onion hub -> cheap onion
      case 'mh_lasalgaon':
        if (cropId == 6) return 0.75; // 25% cheaper onion
        if (cropId == 5) return 0.95;
        return 1.0;

      // Agra UP is Potato hub -> cheap potato
      case 'up_agra':
        if (cropId == 4) return 0.80; // 20% cheaper potato
        return 1.0;

      // Azadpur (Delhi) is consumer hub -> slight premium on all crops
      case 'del_azadpur':
        return 1.08;
      
      case 'del_okhla':
        return 1.05;
      
      // Bangalore Yeshwanthpur -> higher price for North staples like Wheat due to transport
      case 'ka_yeshwanthpur':
        if (cropId == 0) return 1.15; // 15% transport premium
        if (cropId == 4) return 1.10;
        return 1.03;

      default:
        return 1.0;
    }
  }

  /// Helper to get crop harvest month matching train_model.py
  static int _getCropHarvestMonth(int cropId) {
    // Wheat: 4, Rice: 11, Maize: 9, Cotton: 12, Potato: 2, Tomato: 6, Onion: 5, Sugarcane: 1
    const harvestMonths = {0: 4, 1: 11, 2: 9, 3: 12, 4: 2, 5: 6, 6: 5, 7: 1};
    return harvestMonths[cropId] ?? 4;
  }

  /// Calculates the current Mandi price for a crop based on weather & location
  static double getCurrentMandiPrice(Mandi mandi, Crop crop, double temperature, double rainfall, double humidity, int month) {
    double price = crop.basePrice;

    // 1. Mandi Regional Modifier
    price *= getMandiPriceModifier(mandi, crop.id);

    // 2. Seasonality Factor
    final harvestMonth = _getCropHarvestMonth(crop.id);
    final monthsSinceHarvest = (month - harvestMonth) % 12;
    double seasonFactor = 1.0;
    if (monthsSinceHarvest == 0) {
      seasonFactor = 0.8;  // Harvest month: price is low
    } else if (monthsSinceHarvest <= 2) {
      seasonFactor = 0.85; // Post-harvest: price remains relatively low
    } else if (monthsSinceHarvest >= 9) {
      seasonFactor = 1.25; // Pre-harvest: scarcity drives price up
    } else {
      seasonFactor = 1.05; // Normal off-season
    }
    price *= seasonFactor;

    // 3. Weather factors
    // Temperature deviation
    final tempDev = (temperature - crop.optimalTemp).abs();
    double tempFactor = 1.0;
    if (tempDev > 10.0) {
      tempFactor = 1.3;  // Extreme weather hurts yield -> price spikes
    } else if (tempDev > 5.0) {
      tempFactor = 1.1;
    } else {
      tempFactor = 0.95; // Perfect weather -> stabilizing
    }
    price *= tempFactor;

    // Rainfall deviation
    final rainDevRatio = rainfall / crop.optimalRain;
    double rainFactor = 1.0;
    if (rainDevRatio < 0.3) {
      rainFactor = 1.4;  // Drought -> price spikes
    } else if (rainDevRatio > 2.5) {
      rainFactor = 1.35; // Flood -> price spikes
    } else if (0.8 <= rainDevRatio && rainDevRatio <= 1.5) {
      rainFactor = 0.9;  // Ideal rain -> stable/cheaper
    }
    price *= rainFactor;

    // Clip minimum price to 50% of base price
    return price.clamp(crop.basePrice * 0.5, crop.basePrice * 3.0);
  }

  /// Compiles dynamic price reasons (explanations)
  static List<MandiPriceReason> getPredictionReasons({
    required Mandi mandi,
    required Crop crop,
    required double temp,
    required double rain,
    required double hum,
    required int month,
  }) {
    List<MandiPriceReason> reasons = [];
    final lang = LocalizationService.currentLanguage.value;

    // 1. Temperature Check
    final tempDiff = temp - crop.optimalTemp;
    if (tempDiff.abs() > 8.0) {
      final isHigh = tempDiff > 0;
      final desc = lang == 'hi'
          ? "तापमान अनुकूल (${crop.optimalTemp}°C) से ${tempDiff.abs().toStringAsFixed(1)}°C ${isHigh ? 'अधिक' : 'कम'} है। इससे फसल तनाव में है, पैदावार घटेगी।"
          : lang == 'pa'
              ? "ਤਾਪਮਾਨ ਅਨੁਕੂਲ (${crop.optimalTemp}°C) ਤੋਂ ${tempDiff.abs().toStringAsFixed(1)}°C ${isHigh ? 'ਵੱਧ' : 'ਘੱਟ'} ਹੈ। ਇਸ ਨਾਲ ਫਸਲ ਤਣਾਅ ਵਿੱਚ ਹੈ, ਪੈਦਾਵਾਰ ਘਟੇਗੀ।"
              : "Temperature is ${tempDiff.abs().toStringAsFixed(1)}°C ${isHigh ? 'above' : 'below'} optimal (${crop.optimalTemp}°C). Extreme heat/cold stresses plants and reduces yields.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'तापमान का प्रभाव' : lang == 'pa' ? 'ਤਾਪਮਾਨ ਦਾ ਪ੍ਰਭਾਵ' : 'Temperature Stress',
        description: desc,
        impact: 'positive',
        valueText: '+15%',
        icon: Icons.thermostat,
        color: Colors.orange,
      ));
    } else if (tempDiff.abs() <= 3.0) {
      final desc = lang == 'hi'
          ? "तापमान अनुकूल (${crop.optimalTemp}°C) के बहुत करीब है। यह आदर्श स्थिति बंपर पैदावार सुनिश्चित करेगी।"
          : lang == 'pa'
              ? "ਤਾਪਮਾਨ ਅਨੁਕੂਲ (${crop.optimalTemp}°C) ਦੇ ਬਹੁਤ ਨੇੜੇ ਹੈ। ਇਹ ਆਦਰਸ਼ ਸਥਿਤੀ ਵਧੀਆ ਪੈਦਾਵਾਰ ਯਕੀਨੀ ਬਣਾਏਗੀ।"
              : "Temperature is within ±3°C of optimal (${crop.optimalTemp}°C). This provides excellent metabolic growth conditions.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'आदर्श तापमान' : lang == 'pa' ? 'ਆਦਰਸ਼ ਤਾਪਮਾਨ' : 'Optimal Temperature',
        description: desc,
        impact: 'negative',
        valueText: '-5%',
        icon: Icons.done_all,
        color: Colors.teal,
      ));
    }

    // 2. Rainfall Check
    final rainRatio = rain / crop.optimalRain;
    if (rainRatio < 0.3) {
      final desc = lang == 'hi'
          ? "बारिश बहुत कम (${rain.toStringAsFixed(0)} मिमी) है, जो अनुकूल (${crop.optimalRain} मिमी) से काफी नीचे है। गंभीर नमी की कमी पैदावार को घटा रही है।"
          : lang == 'pa'
              ? "ਮੀਂਹ ਬਹੁਤ ਘੱਟ (${rain.toStringAsFixed(0)} ਮਿਮੀ) ਹੈ, ਜੋ ਅਨੁਕੂਲ (${crop.optimalRain} ਮਿਮੀ) ਤੋਂ ਕਾਫੀ ਹੇਠਾਂ ਹੈ। ਗੰਭੀਰ ਨਮੀ ਦੀ ਕਮੀ ਕਾਰਨ ਪੈਦਾਵਾਰ ਘਟੇਗੀ।"
              : "Rainfall is extremely low (${rain.toStringAsFixed(0)}mm vs optimal ${crop.optimalRain}mm). Drought stress slows plant growth, leading to tight market supply.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'सूखे की स्थिति' : lang == 'pa' ? 'ਸੋਕੇ ਦੀ ਸਥਿਤੀ' : 'Moisture Deficit',
        description: desc,
        impact: 'positive',
        valueText: '+20%',
        icon: Icons.water_damage,
        color: Colors.red,
      ));
    } else if (rainRatio > 2.2) {
      final desc = lang == 'hi'
          ? "बारिश अनुकूल (${crop.optimalRain} मिमी) से दोगुनी से अधिक है। बाढ़ की स्थिति से फसल नष्ट होने और सड़ने का खतरा है।"
          : lang == 'pa'
              ? "ਮੀਂਹ ਅਨੁਕੂਲ (${crop.optimalRain} ਮਿਮੀ) ਤੋਂ ਦੁੱਗਣੇ ਤੋਂ ਵੀ ਵੱਧ ਹੈ। ਹੜ੍ਹ ਵਰਗੀ ਸਥਿਤੀ ਕਾਰਨ ਫਸਲਾਂ ਦੇ ਨੁਕਸਾਨ ਦਾ ਖਤਰਾ ਹੈ।"
              : "Rainfall is excessive (${rain.toStringAsFixed(0)}mm vs optimal ${crop.optimalRain}mm). Waterlogging restricts root respiration, threatening crop rotting.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'अत्यधिक वर्षा' : lang == 'pa' ? 'ਬਹੁਤ ਜ਼ਿਆਦਾ ਮੀਂਹ' : 'Excessive Rainfall',
        description: desc,
        impact: 'positive',
        valueText: '+18%',
        icon: Icons.thunderstorm,
        color: Colors.blue,
      ));
    } else if (0.8 <= rainRatio && rainRatio <= 1.4) {
      final desc = lang == 'hi'
          ? "वर्षा का स्तर फसल के अनुकूल है। पर्याप्त जल आपूर्ति से भरपूर फसल उत्पादन में मदद मिलेगी।"
          : lang == 'pa'
              ? "ਮੀਂਹ ਦਾ ਪੱਧਰ ਫਸਲ ਲਈ ਬਹੁਤ ਵਧੀਆ ਹੈ। ਪਾਣੀ ਦੀ ਸਹੀ ਸਪਲਾਈ ਨਾਲ ਵਧੀਆ ਝਾੜ ਮਿਲੇਗਾ।"
              : "Rainfall is in the optimal range. Healthy crop hydration supports high quality and volume of harvests.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'संतुलित वर्षा' : lang == 'pa' ? 'ਸੰਤੁਲਿਤ ਮੀਂਹ' : 'Balanced Rainfall',
        description: desc,
        impact: 'negative',
        valueText: '-8%',
        icon: Icons.cloud_done,
        color: Colors.teal,
      ));
    }

    // 3. Seasonality Check
    final harvestMonth = _getCropHarvestMonth(crop.id);
    final monthsSinceHarvest = (month - harvestMonth) % 12;
    if (monthsSinceHarvest == 0) {
      final desc = lang == 'hi'
          ? "यह फसल की कटाई का महीना है। मंडियों में ताजी आवक की बाढ़ से बाजार की कीमतें काफी कम हो जाएंगी।"
          : lang == 'pa'
              ? "ਇਹ ਫਸਲ ਦੀ ਵਾਢੀ ਦਾ ਮਹੀਨਾ ਹੈ। ਮੰਡੀਆਂ ਵਿੱਚ ਨਵੀਂ ਫਸਲ ਆਉਣ ਕਾਰਨ ਕੀਮਤਾਂ ਘਟਣਗੀਆਂ।"
              : "Harvest season peak. Massive fresh arrivals hit the market this month, creating short-term surplus and lowering prices.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'कटाई का सीजन' : lang == 'pa' ? 'ਵਾਢੀ ਦਾ ਸੀਜ਼ਨ' : 'Harvest Glut',
        description: desc,
        impact: 'negative',
        valueText: '-20%',
        icon: Icons.agriculture,
        color: Colors.green,
      ));
    } else if (monthsSinceHarvest >= 9) {
      final desc = lang == 'hi'
          ? "कटाई का समय पास आ रहा है और पुराना स्टॉक समाप्त हो चुका है। पूर्व-कटाई की कमी के कारण कीमतें रिकॉर्ड ऊंचाई पर हैं।"
          : lang == 'pa'
              ? "ਵਾਢੀ ਦਾ ਸਮਾਂ ਨੇੜੇ ਹੈ ਅਤੇ ਪੁਰਾਣਾ ਸਟਾਕ ਖਤਮ ਹੋ ਰਿਹਾ ਹੈ। ਕਮੀ ਕਾਰਨ ਕੀਮਤਾਂ ਸਭ ਤੋਂ ਉੱਚੇ ਪੱਧਰ 'ਤੇ ਹੋਣਗੀਆਂ।"
              : "Pre-harvest lean period. Storage stocks are depleted as farmers prepare for the next crop, driving prices to their annual peaks.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'पूर्व-कटाई कमी' : lang == 'pa' ? 'ਵਾਢੀ ਤੋਂ ਪਹਿਲਾਂ ਦੀ ਕਮੀ' : 'Pre-harvest Scarcity',
        description: desc,
        impact: 'positive',
        valueText: '+25%',
        icon: Icons.pending_actions,
        color: Colors.amber,
      ));
    }

    // 4. Mandi Premium/Discount Check
    final modifier = getMandiPriceModifier(mandi, crop.id);
    if (modifier < 0.95) {
      final percent = ((1.0 - modifier) * 100).toStringAsFixed(0);
      final desc = lang == 'hi'
          ? "यह मंडी इस फसल के उत्पादक क्षेत्र के करीब है। प्रचुर मात्रा में आपूर्ति होने से यहाँ कीमतें राष्ट्रीय औसत से $percent% सस्ती हैं।"
          : lang == 'pa'
              ? "ਇਹ ਮੰਡੀ ਇਸ ਫਸਲ ਦੇ ਉਤਪਾਦਕ ਖੇਤਰ ਦੇ ਨੇੜੇ ਹੈ। ਸਥਾਨਕ ਸਪਲਾਈ ਵਧੇਰੇ ਹੋਣ ਕਰਕੇ ਕੀਮਤਾਂ ਰਾਸ਼ਟਰੀ ਔਸਤ ਨਾਲੋਂ $percent% ਸਸਤੀਆਂ ਹਨ।"
              : "Mandi is located in the agricultural hub for this crop. Abundant local supply keeps prices $percent% below the national baseline.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'स्थानीय मंडी छूट' : lang == 'pa' ? 'ਮੰਡੀ ਸਥਾਨਕ ਛੋਟ' : 'Mandi Surplus Discount',
        description: desc,
        impact: 'negative',
        valueText: '-$percent%',
        icon: Icons.local_offer,
        color: Colors.teal.shade300,
      ));
    } else if (modifier > 1.03) {
      final percent = ((modifier - 1.0) * 100).toStringAsFixed(0);
      final desc = lang == 'hi'
          ? "महानगरीय उपभोक्ता केंद्र होने या परिवहन लागत के कारण इस मंडी में कीमतें राष्ट्रीय औसत से $percent% अधिक हैं।"
          : lang == 'pa'
              ? "ਮਹਾਂਨਗਰ ਖਪਤਕਾਰ ਕੇਂਦਰ ਹੋਣ ਜਾਂ ਆਵਾਜਾਈ ਖਰਚਿਆਂ ਕਾਰਨ ਇਸ ਮੰਡੀ ਵਿੱਚ ਕੀਮਤਾਂ ਰਾਸ਼ਟਰੀ ਔਸਤ ਨਾਲੋਂ $percent% ਵੱਧ ਹਨ।"
              : "High transport logistics markup and consumer demand in this metropolitan market add a $percent% premium.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'परिवहन/मांग प्रीमियम' : lang == 'pa' ? 'ਟਰਾਂਸਪੋਰਟ ਪ੍ਰੀਮੀਅਮ' : 'Logistics Premium',
        description: desc,
        impact: 'positive',
        valueText: '+$percent%',
        icon: Icons.local_shipping,
        color: Colors.deepOrange,
      ));
    }

    // If no specific weather shocks exist, add a general market reason
    if (reasons.isEmpty) {
      final desc = lang == 'hi'
          ? "बाजार की स्थिति सामान्य है। स्थानीय आपूर्ति और मांग स्थिर बनी हुई है।"
          : lang == 'pa'
              ? "ਬਾਜ਼ਾਰ ਦੀ ਸਥਿਤੀ ਸਧਾਰਨ ਹੈ। ਮੰਗ ਅਤੇ ਸਪਲਾਈ ਸਥਿਰ ਬਣੀ ਹੋਈ ਹੈ।"
              : "The market is operating with high volume liquidity and standard buyer demand, ensuring stable price action.";
      reasons.add(MandiPriceReason(
        title: lang == 'hi' ? 'संतुलित बाजार' : lang == 'pa' ? 'ਸੰਤੁਲਿਤ ਬਾਜ਼ਾਰ' : 'Stable Market Dynamics',
        description: desc,
        impact: 'neutral',
        valueText: '0%',
        icon: Icons.balance,
        color: Colors.blueGrey,
      ));
    }

    return reasons;
  }
}
