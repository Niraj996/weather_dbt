

-- Average weather across continents during different seasons
WITH seasonal_data AS (
    SELECT 
        continent,
        season,
        temperature,
        humidity,
        pressure,
        wind_speed,
        timestamp
    FROM "weather_db"."analytics_staging"."stg_weather_data"
    WHERE season IS NOT NULL
)

SELECT 
    continent,
    season,
    COUNT(*) AS num_observations,
    COUNT(DISTINCT DATE(timestamp)) AS num_days,
    ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
    ROUND(AVG(pressure)::numeric, 2) AS avg_pressure,
    ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed,
    ROUND(MIN(temperature)::numeric, 2) AS min_temperature,
    ROUND(MAX(temperature)::numeric, 2) AS max_temperature,
    ROUND(STDDEV(temperature)::numeric, 2) AS temperature_variance,
    MAX(timestamp) AS last_updated
FROM seasonal_data
GROUP BY continent, season
ORDER BY continent, 
    CASE season 
        WHEN 'Spring' THEN 1
        WHEN 'Summer' THEN 2
        WHEN 'Fall' THEN 3
        WHEN 'Winter' THEN 4
    END