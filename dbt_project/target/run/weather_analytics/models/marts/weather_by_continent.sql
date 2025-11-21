
  
    

  create  table "weather_db"."analytics_analytics"."weather_by_continent__dbt_tmp"
  
  
    as
  
  (
    

-- Overall weather statistics by continent
WITH continent_data AS (
    SELECT 
        continent,
        climate_zone,
        temperature,
        humidity,
        pressure,
        wind_speed,
        weather_main,
        timestamp
    FROM "weather_db"."analytics_staging"."stg_weather_data"
)

SELECT 
    continent,
    climate_zone,
    COUNT(*) AS num_observations,
    COUNT(DISTINCT weather_main) AS weather_variety,
    ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
    ROUND(AVG(pressure)::numeric, 2) AS avg_pressure,
    ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed,
    MODE() WITHIN GROUP (ORDER BY weather_main) AS most_common_weather,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY temperature)::numeric, 2) AS median_temperature,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY temperature)::numeric, 2) AS temp_25th_percentile,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY temperature)::numeric, 2) AS temp_75th_percentile,
    MAX(timestamp) AS last_updated
FROM continent_data
GROUP BY continent, climate_zone
ORDER BY continent, climate_zone
  );
  