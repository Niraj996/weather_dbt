**README.md**

# Weather ELT Project with dbt

This project implements a complete **Extract, Load, Transform (ELT)** pipeline for weather data. 
The pipeline extracts real-time weather data from the **WeatherAPI**, loads it into **PostgreSQL**, transforms the data using **dbt**, and caches the results in **Redis**.  
All components are containerised using **Docker**, allowing for easy deployment and scalability.

---

## Table of Contents
1. [Overview](#overview)  
2. [Features](#features)
3. [Technologies Used](#technologies-used) 
4. [Project Structure](#project-structure)
5. [Prerequisites](#prerequisites)
6. [Installation](#installation)
7. [Configuration](#configuration)
8. [Running the Pipeline](#running-the-pipeline)
9. [Using the Data](#using-the-data)
10. [dbt Models Explanation](#dbt-models-explanation)
11. [Contributing](#contributing)
12. [License](#license)

---

## Overview <a name="overview"></a>

This project collects weather data from multiple locations, stores the raw data in PostgreSQL and then uses **dbt** to create transformed and aggregated datasets ready for analysis. 
The transformed data is then stored in **Redis** allowing for low—latency data retrieval.

The ELT pipeline consists of the following steps.

1.  **Extract**  Weather data from  [WeatherAPI](https://www.weatherapi.com/)
2.  **Load** Raw data into **PostgreSQL**
3.  **Transform** Data using **dbt**. The transformations include;
    *   Average weather along the equator.
    *   Seasonal averages per continent.
    *   Averages per latitude bands.
4.  **Load** Transformed data into **Redis** in `JSON` format.   

All services are managed using **Docker Compose**, creating a reproducible environment.

---

## Features <a name="features"></a>

✅ Real-time weather data extraction from WeatherAPI  
✅ Automated data loading into PostgreSQL  
✅ Data transformation using dbt   
✅ Caching transformed data in Redis     
✅  Fully containerised with Docker  
✅ Easy to run pipeline with `make` commands  
✅ Comprehensive data analysis models  

---

## Technologies Used <a name="technologies-used"></a>

- **Python**  — Scripting for data extraction and loading
- **PostgreSQL** — Relational database for storing raw data
- **Redis** — In-memory data store used for caching transformed data
- **dbt (Data Build Tool)** — Transformation of data using SQL
- **Docker & Docker Compose** — Containerisation and orchestration 
- **WeatherAPI** — Weather data provider   

---

## Project Structure <a name="project-structure"></a>

```
weather_dbt/
├── docker-compose.yml          # Docker compose configuration
├── .env                       # Environment variables 
├── Dockerfile.etl             # Dockerfile for the ETL container
├── requirements.txt           # Python dependencies
├── Makefile                   # Commands to run the pipeline
├── README.md                  
├── scripts/
│   ├── extract_weather.py     # Extracts data from WeatherAPI & loads to Postgres
│   └── postgres_to_redis.py   # Loads transformed data from Postgres to Redis
├── sql/
│   └── init.sql               # PostgreSQL initialisation script
├── dbt_project/               # dbt project folder
│   ├── dbt_project.yml
│   ├── profiles.yml           
│   ├── models/
│   │   ├── staging/                     
│   │   │   ├── stg_weather_data.sql
│   │   │   └── schema.yml
│   │   └── marts/                        
│   │       ├── equator_weather_avg.sql
│   │       ├── weather_by_latitude.sql
│   │       ├── weather_by_continent.sql
│   │       └── seasonal_continent_avg.sql
│   └── seeds/
│       └── continent_coordinates.csv
```

---

## Prerequisites <a name="prerequisites"></a>

To run this project you will need the following installed on your machine.

🔹 [**Docker**](https://www.docker.com/) & [**Docker Compose**](https://docs.docker.com/compose/)   
🔹 **Git**   

> **Note** Docker Compose V2  (`docker compose`)  is required. To verify run `docker compose version`

---

## Installation <a name="installation"></a>

Follow the steps below to setup the project.

### 1. Clone the Repository

```bash
git clone https://github.com/Niraj996/weather_dbt.git
cd weather_dbt
```

### 2. Create `.env` file

In the root directory create a `.env` file and add your details.
You will need an API key from **[WeatherAPI](https://www.weatherapi.com/)**. After signing up navigate to the dashboard to find your API key.

```env
POSTGRES_USER=weather_user
POSTGRES_PASSWORD=weather_pass123
WEATHER_API_KEY=your_weatherapi_key_here
```   

> ⚠️ **DO NOT** commit the `.env` file to Git.

### 3. Start the Services

Run the following command to start all the services.

```bash 
make up
```   

Docker Compose will create the following containers.

*   `weather_postgres`  — PostgreSQL database 
*   `weather_redis` — Redis database
*   `weather_dbt` — Contains the dbt project and python scripts   

Once all containers are running you will see 

```
✅ Container weather_postgres   Healthy   
✅ Container weather_redis     Healthy  
✅ Container weather_dbt       Created 
```

---

## Configuration <a name="configuration"></a>

All configuration is performed through the `.env` file.   

🔹 **`POSTGRES_USER`** & **`POSTGRES_PASSWORD`**   
Credentials for the PostgreSQL database. These are also used in `dbt_project/profiles.yml`

🔹 **`WEATHER_API_KEY`**  
Your WeatherAPI API key.

---

## Running the Pipeline <a name="running-the-pipeline"></a>

The entire ELT pipeline can be run with a single command.

### Run the complete pipeline

```bash
make pipeline
```   

The command executes the following steps in order.

1.  **`extract`**  Extracts data from WeatherAPI and loads it into PostgreSQL.
2.  **`dbt-run`** Runs all dbt models to transform the data.
3.  **`load-redis`** Loads the transformed data from PostgreSQL to Redis.   

You can also run each step individually.

```bash
make extract          # Extract & Load data into Postgres
make dbt-run          # Run dbt transformations
make load-redis       # Load transformed data into Redis
```

---

## Using the Data <a name="using-the-data"></a>

### Querying PostgreSQL

To view data in PostgreSQL you can use the built-in shell.

```bash
make shell-postgres
```

Once inside `psql` you can run queries.

**Raw Data**

```sql
SELECT * FROM raw.weather_data LIMIT 5;
```

**Transformed Data**

```sql
-- Average weather along the equator
SELECT * FROM analytics.equator_weather_avg;

-- Seasonal averages per continent
SELECT * FROM analytics.seasonal_continent_avg;

-- Averages per latitude band
SELECT * FROM analytics.weather_by_latitude;
```

### Querying Redis

To access the data cached in Redis use the Redis shell.

```bash
make shell-redis
```

Inside the CLI you can retrieve the data.

**All cities**

```redis
GET weather:all
```   

The response will be a JSON array containing all the latest weather data.

**Single City**

```redis
GET weather:london
```

The response will be a JSON object with the data for London.

> 🔎 The keys in Redis are generated using the city name. Spaces are replaced with `_` and the name is lowercased.  e.g. `London` →  `weather:london`

---

## dbt Models Explanation <a name="dbt-models-explanation"></a">

The dbt project is located in the `dbt_project` folder. Below is an explanation of the models.

### Staging Models

`models/staging/stg_weather_data.sql`

Creates a view that cleans and enriches the raw data.
The following columns are added.

🔹 **`season`**   
Determines the season based on the date and latitude.
🔹 **`climate_zone`**  
Classifies the location into a climate zone *(Tropical, Temperate, Polar)* based on the latitude.

A schema test is included in  `models/staging/schema.yml` to validate data quality.

---

### Mart Models

All mart models are located in `models/marts/`. They are materialised as tables.

📌 **`equator_weather_avg.sql`**   

Calculates the average weather metrics for cities within **5 degrees** of the equator.

📌 **`weather_by_latitude.sql`**  

Aggregates the weather data into latitude bands.
*   60+N  Arctic
*   45-60+N Northern Temperate
*   23.5-45+N Subtropical 
*   0-23.5+N Tropical 
*   0-23.5+S Tropical 
*   23.5-45+S Subtropical
*   45-60+S Southern Temperate
*   60+S Antarctic

📌 **`weather_by_continent.sql`**

Provides overall weather statistics for each continent.  
It uses the `continent_coordinates.csv` seed file to determine which continent a city belongs to.

📌 **`seasonal_continent_avg.sql`**  

Calculates the average weather for each continent during each season *(Spring, Summer, Fall, Winter)*.

You can run tests for all models with 

```bash
make dbt-test
```
