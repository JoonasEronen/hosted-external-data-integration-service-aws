import datetime
import logging
from zoneinfo import ZoneInfo

import httpx

from app.database.repository import save_ingestion_run
from app.domain.weather import (
    WEATHER_EMOJI,
    WEATHER_TEXT,
    wind_arrow,
    wind_direction_to_compass,
)

logger = logging.getLogger(__name__)

############################################
# External data ingestion service
############################################
# Handles:
# - external API calls
# - response transformation
# - ingestion run tracking


############################################
# Ingestion job
############################################
# Periodic ingestion job that:
# - fetches weather data from an external API
# - transforms selected response fields
# - stores ingestion metadata to PostgreSQL
#
# In this MVP phase, the service stores ingestion run metadata
# together with a lightweight city-level weather snapshot.
# It does not persist the full raw API response.
def run_ingestion_job():
    now = datetime.datetime.now(datetime.timezone.utc)

    logger.info("Data ingestion job started source=open-meteo")

    # Demo locations used to simulate a recurring external data feed.
    cities = [
        {"name": "Helsinki", "latitude": 60.17, "longitude": 24.94},
        {"name": "Stockholm", "latitude": 59.33, "longitude": 18.07},
        {"name": "New York", "latitude": 40.71, "longitude": -74.01},
    ]

    current_city = None

    try:
        city_results = []

        for city in cities:
            # Open-Meteo current weather endpoint for one city.
            url = (
                "https://api.open-meteo.com/v1/forecast"
                f"?latitude={city['latitude']}"
                f"&longitude={city['longitude']}"
                "&current_weather=true"
            )

            current_city = city["name"]
            logger.info("Fetching external weather data city=%s", current_city)

            # Fetch current weather from the external provider.
            response = httpx.get(url, timeout=10)
            response.raise_for_status()

            data = response.json()
            current_weather = data["current_weather"]

            weather_code = current_weather["weathercode"]
            wind_dir = current_weather["winddirection"]

            local_tz = ZoneInfo("Europe/Helsinki")
            observed_local = (
                datetime.datetime.fromisoformat(current_weather["time"])
                .replace(tzinfo=datetime.timezone.utc)
                .astimezone(local_tz)
                .strftime("%H:%M %Z")
            )

            # Transform raw provider fields into a more readable structure.
            city_results.append(
                {
                    "city": city["name"],
                    "observed_at": current_weather["time"],
                    "observed_local": observed_local,
                    "temperature": current_weather["temperature"],
                    "weathercode": weather_code,
                    "weather_emoji": WEATHER_EMOJI.get(weather_code, "❓"),
                    "weather_text": WEATHER_TEXT.get(weather_code, "Unknown"),
                    "windspeed": current_weather["windspeed"],
                    "winddirection": wind_dir,
                    "wind_compass": wind_direction_to_compass(wind_dir),
                    "wind_arrow": wind_arrow(wind_dir),
                }
            )

        # Record a successful ingestion run.       
        run = {
            "source_name": "Open-Meteo API",
            "status": "success",
            "started_at": now,
            "finished_at": datetime.datetime.now(datetime.timezone.utc),
            "records_fetched": len(city_results),
            "error_message": None,
            "city_results": city_results,
        }

        logger.info("Data ingestion job completed successfully records_fetched=%d", len(city_results))

    except Exception as e:
        # Record a failed ingestion run for operational visibility.
        run = {
            "source_name": "Open-Meteo API",
            "status": "failed",
            "started_at": now,
            "finished_at": datetime.datetime.now(datetime.timezone.utc),
            "records_fetched": 0,
            "error_message": str(e),
            "city_results": [],
        }
        logger.exception("Data ingestion job failed city=%s", current_city)

    # Persist ingestion run metadata to PostgreSQL.
    save_ingestion_run(run)
    
    logger.info(
        "Ingestion run saved to PostgreSQL status=%s records_fetched=%d",
        run["status"],
        run["records_fetched"],
    )