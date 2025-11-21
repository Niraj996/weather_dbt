#!/usr/bin/env python3
#!/usr/bin/env python3
import os
import json
import requests
import psycopg2
from datetime import datetime
try:
    from dotenv import load_dotenv
except Exception:
    # python-dotenv not installed; provide a no-op fallback so the script still runs
    def load_dotenv():
        return None
import time

load_dotenv()

# Configuration
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'localhost'),
    'database': os.getenv('POSTGRES_DB', 'weather_db'),
    'user': os.getenv('POSTGRES_USER'),
    'password': os.getenv('POSTGRES_PASSWORD')
}

API_KEY = os.getenv('WEATHER_API_KEY')
BASE_URL = "https://api.weatherapi.com/v1/current.json"

# Cities with continent information
# Using IP addresses as the endpoint requires an IP, lat/lon or city name.
# We will use the latitude & longitude to query the API
CITIES = [
    # Equator cities
    {"name": "Quito", "country": "EC", "continent": "South America", "lat": -0.22, "lon": -78.51},
    {"name": "Kampala", "country": "UG", "continent": "Africa", "lat": 0.32, "lon": 32.58},
    {"name": "Singapore", "country": "SG", "continent": "Asia", "lat": 1.29, "lon": 103.85},
    {"name": "Nairobi", "country": "KE", "continent": "Africa", "lat": -1.29, "lon": 36.82},
    
    # Other major cities
    {"name": "London", "country": "GB", "continent": "Europe", "lat": 51.517, "lon": -0.106},
    {"name": "New York", "country": "US", "continent": "North America", "lat": 40.71, "lon": -74.01},
    {"name": "Tokyo", "country": "JP", "continent": "Asia", "lat": 35.68, "lon": 139.69},
    {"name": "Sydney", "country": "AU", "continent": "Australia", "lat": -33.87, "lon": 151.21},
    {"name": "Cairo", "country": "EG", "continent": "Africa", "lat": 30.04, "lon": 31.24},
    {"name": "Moscow", "country": "RU", "continent": "Europe", "lat": 55.76, "lon": 37.62},
    {"name": "Rio de Janeiro", "country": "BR", "continent": "South America", "lat": -22.91, "lon": -43.17},
    {"name": "Mumbai", "country": "IN", "continent": "Asia", "lat": 19.08, "lon": 72.88},
]


def fetch_weather(city_data):
    """Fetch weather data for a city using WeatherAPI"""
    
    #Use latitude & longitude to query the API
    params = {
        'q': f"{city_data['lat']},{city_data['lon']}",
        'lang': 'ja',                     # Language set to Japanese as per your example
        'key': API_KEY
    }
    
    try:
        response = requests.get(BASE_URL, params=params)
        response.raise_for_status()
        data = response.json()
        
        #Extract data from the new JSON structure
        location = data["location"]
        current = data["current"]
        
        return {
            'city': location['name'],
            'country': location['country'],
            'continent': city_data['continent'], #We still use the predefined continent
            'latitude': location['lat'],
            'longitude': location['lon'],
            'temperature': current['temp_c'],                   # Celsius
            'feels_like': current['feelslike_c'],               # Celsius
            'humidity': current['humidity'],
            'pressure': current['pressure_mb'],                 #  millibars
            'wind_speed': current['wind_kph'],                 # kph
            'weather_main': current['condition']['code'],       # Condition code
            'weather_description': current['condition']['text'], # Condition text
            'timestamp': datetime.fromtimestamp(location['localtime_epoch'] / 1000), # Convert epoch to datetime
            'cloud': current['cloud'],                         #Cloud cover %
            'precipitation': current['precip_mm']              #mm
        }
    except Exception as e:
        print(f"Error fetching weather for {city_data['name']}: {e}")
        return None

def save_to_postgres(weather_data):
    """Save weather data to PostgreSQL"""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    insert_query = """
        INSERT INTO raw.weather_data 
        (city, country, continent, latitude, longitude, temperature, 
         feels_like, humidity, pressure, wind_speed, weather_main, 
         weather_description, timestamp, cloud, precipitation)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    cur.execute(insert_query, (
        weather_data['city'],
        weather_data['country'],
        weather_data['continent'],
        weather_data['latitude'],
        weather_data['longitude'],
        weather_data['temperature'],
        weather_data['feels_like'],
        weather_data['humidity'],
        weather_data['pressure'],
        weather_data['wind_speed'],
        weather_data['weather_main'],
        weather_data['weather_description'],
        weather_data['timestamp'],
        weather_data['cloud'],
        weather_data['precipitation']
    ))
    
    conn.commit()
    cur.close()
    conn.close()

def main():
    """Main extraction function"""
    print(f"Starting weather extraction at {datetime.now()}")
    
    for city in CITIES:
        weather_data = fetch_weather(city)
        if weather_data:
            save_to_postgres(weather_data)
            print(f"Saved weather data for {city['name']}")
        time.sleep(1)  # Rate limiting
    
    print(f"Extraction completed at {datetime.now()}")

if __name__ == "__main__":
    main()