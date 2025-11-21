

-- Average weather along the equator (within 5 degrees latitude)
WITH equator_data AS (
    SELECT 
        *,
        ABS(latitude) AS distance_from_equator
    FROM "weather_db"."analytics_staging"."stg_weather_data"
    WHERE ABS(latitude) <= 5
)

SELECT 
    'Equator Region' AS region,
    COUNT(DISTINCT city) AS num_cities,
    ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
    ROUND(AVG(feels_like)::numeric, 2) AS avg_feels_like,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
    ROUND(AVG(pressure)::numeric, 2) AS avg_pressure,
    ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed,
    MIN(temperature) AS min_temperature,
    MAX(temperature) AS max_temperature,
    ROUND(AVG(distance_from_equator)::numeric, 2) AS avg_distance_from_equator,
    MAX(timestamp) AS last_updated
FROM equator_data