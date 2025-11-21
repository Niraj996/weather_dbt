{{
    config(
        materialized='table'
    )
}}

-- Average weather by latitude bands
WITH latitude_bands AS (
    SELECT 
        *,
        CASE 
            WHEN latitude >= 60 THEN '60+ North (Arctic)'
            WHEN latitude >= 45 THEN '45-60 North (Northern Temperate)'
            WHEN latitude >= 23.5 THEN '23.5-45 North (Subtropical)'
            WHEN latitude >= 0 THEN '0-23.5 North (Tropical)'
            WHEN latitude >= -23.5 THEN '0-23.5 South (Tropical)'
            WHEN latitude >= -45 THEN '23.5-45 South (Subtropical)'
            WHEN latitude >= -60 THEN '45-60 South (Southern Temperate)'
            ELSE '60+ South (Antarctic)'
        END AS latitude_band,
        FLOOR(latitude / 10) * 10 AS latitude_group
    FROM {{ ref('stg_weather_data') }}
)

SELECT 
    latitude_band,
    latitude_group,
    COUNT(DISTINCT city) AS num_cities,
    ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
    ROUND(AVG(pressure)::numeric, 2) AS avg_pressure,
    ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed,
    ROUND(MIN(temperature)::numeric, 2) AS min_temperature,
    ROUND(MAX(temperature)::numeric, 2) AS max_temperature,
    ROUND(STDDEV(temperature)::numeric, 2) AS temperature_stddev,
    MAX(timestamp) AS last_updated
FROM latitude_bands
GROUP BY latitude_band, latitude_group
ORDER BY latitude_group DESC
