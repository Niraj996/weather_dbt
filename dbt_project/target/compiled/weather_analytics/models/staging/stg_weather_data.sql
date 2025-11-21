-- dbt_project/models/staging/stg_weather_data.sql
SELECT 
    id,
    city,
    country,
    continent,
    latitude,
    longitude,
    temperature,
    feels_like,
    humidity,
    pressure,
    wind_speed,
    weather_main,
    weather_description,
    cloud,
    precipitation,
    timestamp,
    extracted_at,
    -- Derive season based on month and hemisphere
    CASE 
        WHEN EXTRACT(MONTH FROM timestamp) IN (12, 1, 2) AND latitude > 0 THEN 'Winter'
        WHEN EXTRACT(MONTH FROM timestamp) IN (12, 1, 2) AND latitude < 0 THEN 'Summer'
        WHEN EXTRACT(MONTH FROM timestamp) IN (3, 4, 5) AND latitude > 0 THEN 'Spring'
        WHEN EXTRACT(MONTH FROM timestamp) IN (3, 4, 5) AND latitude < 0 THEN 'Fall'
        WHEN EXTRACT(MONTH FROM timestamp) IN (6, 7, 8) AND latitude > 0 THEN 'Summer'
        WHEN EXTRACT(MONTH FROM timestamp) IN (6, 7, 8) AND latitude < 0 THEN 'Winter'
        WHEN EXTRACT(MONTH FROM timestamp) IN (9, 10, 11) AND latitude > 0 THEN 'Fall'
        WHEN EXTRACT(MONTH FROM timestamp) IN (9, 10, 11) AND latitude < 0 THEN 'Spring'
        ELSE 'Unknown'
    END AS season,
    -- Derive climate zone based on latitude
    CASE 
        WHEN ABS(latitude) < 23.5 THEN 'Tropical'
        WHEN ABS(latitude) >= 23.5 AND ABS(latitude) < 35 THEN 'Subtropical'
        WHEN ABS(latitude) >= 35 AND ABS(latitude) < 66.5 THEN 'Temperate'
        WHEN ABS(latitude) >= 66.5 THEN 'Polar'
        ELSE 'Unknown'
    END AS climate_zone
FROM raw.weather_data