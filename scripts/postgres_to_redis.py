#!/usr/bin/env python3
import os
import json
import psycopg2
import redis
from datetime import datetime, date
from decimal import Decimal
from dotenv import load_dotenv

load_dotenv()

# Configuration
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'localhost'),
    'database': os.getenv('POSTGRES_DB', 'weather_db'),
    'user': os.getenv('POSTGRES_USER'),
    'password': os.getenv('POSTGRES_PASSWORD')
}

REDIS_CONFIG = {
    'host': os.getenv('REDIS_HOST', 'localhost'),
    'port': 6379,
    'db': 0
}

class DateTimeEncoder(json.JSONEncoder):
    """Custom JSON encoder for datetime and Decimal"""
    def default(self, obj):
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        elif isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)

def fetch_from_postgres():
    """Fetch latest weather data from PostgreSQL"""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    # Fetch latest data for each city
    query = """
        SELECT DISTINCT ON (city)
            city, country, continent, latitude, longitude, 
            temperature, feels_like, humidity, pressure, 
            wind_speed, weather_main, weather_description, timestamp
        FROM raw.weather_data
        ORDER BY city, timestamp DESC
    """
    
    cur.execute(query)
    columns = [desc[0] for desc in cur.description]
    results = []
    
    for row in cur.fetchall():
        results.append(dict(zip(columns, row)))
    
    cur.close()
    conn.close()
    
    return results

def save_to_redis(data):
    """Save data to Redis in JSON format"""
    r = redis.Redis(**REDIS_CONFIG)
    
    # Save individual city data
    for record in data:
        key = f"weather:{record['city'].lower().replace(' ', '_')}"
        value = json.dumps(record, cls=DateTimeEncoder)
        r.set(key, value)
        r.expire(key, 3600)  # Expire after 1 hour
    
    # Save all data as a list
    all_data_key = "weather:all"
    all_data_value = json.dumps(data, cls=DateTimeEncoder)
    r.set(all_data_key, all_data_value)
    r.expire(all_data_key, 3600)
    
    print(f"Saved {len(data)} records to Redis")

def main():
    """Main function to transfer data from PostgreSQL to Redis"""
    print(f"Starting data transfer at {datetime.now()}")
    
    # Fetch from PostgreSQL
    data = fetch_from_postgres()
    print(f"Fetched {len(data)} records from PostgreSQL")
    
    # Save to Redis
    save_to_redis(data)
    
    print(f"Data transfer completed at {datetime.now()}")

if __name__ == "__main__":
    main()
