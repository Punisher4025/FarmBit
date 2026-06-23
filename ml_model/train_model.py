import numpy as np
import pandas as pd
import os
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor

# Set seed for reproducibility
np.random.seed(42)

# Define crops and baseline prices per kg (in INR)
CROPS = {
    'Wheat': {'base': 25.0, 'temp_opt': 20.0, 'rain_opt': 100.0, 'harvest_month': 4},
    'Rice': {'base': 35.0, 'temp_opt': 27.0, 'rain_opt': 250.0, 'harvest_month': 11},
    'Maize': {'base': 22.0, 'temp_opt': 24.0, 'rain_opt': 120.0, 'harvest_month': 9},
    'Cotton': {'base': 60.0, 'temp_opt': 28.0, 'rain_opt': 80.0, 'harvest_month': 12},
    'Potato': {'base': 15.0, 'temp_opt': 18.0, 'rain_opt': 75.0, 'harvest_month': 2},
    'Tomato': {'base': 30.0, 'temp_opt': 22.0, 'rain_opt': 100.0, 'harvest_month': 6},
    'Onion': {'base': 25.0, 'temp_opt': 20.0, 'rain_opt': 90.0, 'harvest_month': 5},
    'Sugarcane': {'base': 4.0, 'temp_opt': 30.0, 'rain_opt': 300.0, 'harvest_month': 1} # per kg
}

crop_names = list(CROPS.keys())
crop_to_idx = {name: idx for idx, name in enumerate(crop_names)}

def generate_synthetic_data(num_samples=5000):
    data = []
    for _ in range(num_samples):
        crop = np.random.choice(crop_names)
        crop_idx = crop_to_idx[crop]
        month = np.random.randint(1, 13)
        
        # Weather variables based on realistic ranges
        # Wheat/Potato prefer cooler, Sugarcane/Cotton hotter
        temp = np.random.uniform(10.0, 40.0)
        # Rainfall in mm/month
        rain = np.random.uniform(10.0, 500.0)
        # Humidity in %
        humidity = np.random.uniform(30.0, 95.0)
        
        # Calculate price based on crop characteristics
        c_info = CROPS[crop]
        base_price = c_info['base']
        
        # Seasonality effect: prices drop around harvest due to glut, rise before harvest
        months_since_harvest = (month - c_info['harvest_month']) % 12
        if months_since_harvest == 0:
            season_factor = 0.8  # Harvest month: price is low
        elif months_since_harvest <= 2:
            season_factor = 0.85 # Post-harvest: price remains relatively low
        elif months_since_harvest >= 9:
            season_factor = 1.25 # Pre-harvest: scarcity drives price up
        else:
            season_factor = 1.05 # Normal off-season
            
        # Weather effects:
        # 1. Temperature deviation from optimal
        temp_dev = abs(temp - c_info['temp_opt'])
        if temp_dev > 10.0:
            temp_factor = 1.3 # Extreme heat or cold hurts yield -> drives price up
        elif temp_dev > 5.0:
            temp_factor = 1.1
        else:
            temp_factor = 0.95 # Perfect weather -> high yield -> slightly lower price
            
        # 2. Rainfall deviation from optimal
        rain_dev_ratio = rain / c_info['rain_opt']
        if rain_dev_ratio < 0.3:
            rain_factor = 1.4 # Drought -> crop failure -> price spikes
        elif rain_dev_ratio > 2.5:
            rain_factor = 1.35 # Floods -> crop damage -> price spikes
        elif 0.8 <= rain_dev_ratio <= 1.5:
            rain_factor = 0.9 # Good rainfall -> bumper crop -> price stabilizes/lowers
        else:
            rain_factor = 1.0
            
        # Combine factors with some random noise
        noise = np.random.normal(1.0, 0.05) # 5% noise
        price = base_price * season_factor * temp_factor * rain_factor * noise
        
        # Clip minimum price to avoid negative values
        price = max(base_price * 0.5, price)
        
        data.append({
            'crop_idx': crop_idx,
            'month': month,
            'temp': temp,
            'rain': rain,
            'humidity': humidity,
            'price': price
        })
        
    return pd.DataFrame(data)

# Generate data
df = generate_synthetic_data(8000)

# Train a separate decision tree for each crop
crop_names = list(CROPS.keys())
crop_trees_code = ""

def recurse_tree(tree, node_id, indent=""):
    left_child = tree.children_left[node_id]
    right_child = tree.children_right[node_id]
    
    # Check if leaf node
    if left_child == -1 and right_child == -1:
        val = tree.value[node_id][0][0]
        return f"{indent}return {val:.4f};\n"
        
    feature = tree.feature[node_id]
    threshold = tree.threshold[node_id]
    
    feature_names = ['month', 'temperature', 'rainfall', 'humidity']
    feature_name = feature_names[feature]
    
    dart_code = ""
    dart_code += f"{indent}if ({feature_name} <= {threshold:.4f}) {{\n"
    dart_code += recurse_tree(tree, left_child, indent + "  ")
    dart_code += f"{indent}}} else {{\n"
    dart_code += recurse_tree(tree, right_child, indent + "  ")
    dart_code += f"{indent}}}\n"
    return dart_code

for name in crop_names:
    crop_idx = crop_to_idx[name]
    df_crop = df[df['crop_idx'] == crop_idx]
    
    X_crop = df_crop[['month', 'temp', 'rain', 'humidity']]
    y_crop = df_crop['price']
    
    model = DecisionTreeRegressor(max_depth=5, random_state=42)
    model.fit(X_crop, y_crop)
    
    print(f"Decision Tree trained for {name}. R^2 score: {model.score(X_crop, y_crop):.4f}")
    
    tree_body = recurse_tree(model.tree_, 0, "    ")
    
    crop_trees_code += f"""  static double _predict{name}({{
    required int month,
    required double temperature,
    required double rainfall,
    required double humidity,
  }}) {{
{tree_body}  }}

"""

# Main predict method code
predict_switch_cases = ""
for name in crop_names:
    crop_idx = crop_to_idx[name]
    predict_switch_cases += f"""      case {crop_idx}:
        return _predict{name}(
          month: month,
          temperature: temperature,
          rainfall: rainfall,
          humidity: humidity,
        );\n"""

dart_file_content = f"""// This file is auto-generated by train_model.py. Do not edit manually.

class CropPricePredictor {{
  /// Predicts the price of a crop per kg (in INR) based on inputs.
  /// 
  /// Parameters:
  /// - [cropIndex]: 0 for Wheat, 1 for Rice, 2 for Maize, 3 for Cotton, 
  ///   4 for Potato, 5 for Tomato, 6 for Onion, 7 for Sugarcane.
  /// - [month]: 1 (Jan) to 12 (Dec)
  /// - [temperature]: current temperature in Celsius
  /// - [rainfall]: monthly rainfall in mm
  /// - [humidity]: relative humidity in percentage (0 - 100)
  static double predict({{
    required int cropIndex,
    required int month,
    required double temperature,
    required double rainfall,
    required double humidity,
  }}) {{
    switch (cropIndex) {{
{predict_switch_cases}      default:
        return 0.0;
    }}
  }}

{crop_trees_code}}}
"""

# Ensure output directories exist
os.makedirs(os.path.dirname('c:/Users/ayush/Desktop/Crop Price Prediction/lib/services/crop_price_predictor.dart'), exist_ok=True)

with open('c:/Users/ayush/Desktop/Crop Price Prediction/lib/services/crop_price_predictor.dart', 'w') as f:
    f.write(dart_file_content)

print("Generated Dart ML Predictor class successfully!")
