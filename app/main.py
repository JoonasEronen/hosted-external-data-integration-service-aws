from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates
from apscheduler.schedulers.background import BackgroundScheduler
import httpx
import datetime

app = FastAPI()
templates = Jinja2Templates(directory="app/templates")

# Temporary in-memory storage for local development before moving to PostgreSQL
ingestion_runs = []

# Weather code mappings based on Open-Meteo / WMO weather interpretation codes
WEATHER_EMOJI = {
    0: "☀️",
    1: "🌤️",
    2: "⛅",
    3: "☁️",
    45: "🌫️",
    48: "🌫️",
    51: "🌦️",
    53: "🌦️",
    55: "🌧️",
    61: "🌧️",
    63: "🌧️",
    65: "⛈️",
    71: "❄️",
    73: "❄️",
    75: "❄️",
    80: "🌦️",
    81: "🌧️",
    82: "⛈️",
    95: "⛈️",
}

WEATHER_TEXT = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    56: "Light freezing drizzle",
    57: "Dense freezing drizzle",
    61: "Light rain",
    63: "Moderate rain",
    65: "Heavy rain",
    66: "Light freezing rain",
    67: "Heavy freezing rain",
    71: "Light snow",
    73: "Moderate snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Light rain showers",
    81: "Moderate rain showers",
    82: "Violent rain showers",
    85: "Light snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm with hail",
    99: "Thunderstorm with heavy hail",
}


def wind_direction_to_compass(deg):
    directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    index = round(deg / 45) % 8
    return directions[index]


def wind_arrow(deg):
    arrows = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
    index = round(deg / 45) % 8
    return arrows[index]


def run_ingestion_job():
    """Fetch current weather data for multiple cities and store the latest runs in memory."""
    now = datetime.datetime.now(datetime.timezone.utc)

    cities = [
        {"name": "Helsinki", "latitude": 60.17, "longitude": 24.94},
        {"name": "Stockholm", "latitude": 59.33, "longitude": 18.07},
        {"name": "New York", "latitude": 40.71, "longitude": -74.01},
    ]

    try:
        city_results = []

        for city in cities:
            url = (
                "https://api.open-meteo.com/v1/forecast"
                f"?latitude={city['latitude']}"
                f"&longitude={city['longitude']}"
                "&current_weather=true"
            )

            response = httpx.get(url, timeout=10)
            response.raise_for_status()

            data = response.json()
            current_weather = data["current_weather"]

            weather_code = current_weather["weathercode"]
            wind_dir = current_weather["winddirection"]

            city_results.append(
                {
                    "city": city["name"],
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

        run = {
            "timestamp": now.isoformat(),
            "status": "success",
            "source_name": "Open-Meteo API",
            "records_saved": len(city_results),
            "city_results": city_results,
        }

    except Exception as e:
        run = {
            "timestamp": now.isoformat(),
            "status": "failed",
            "source_name": "Open-Meteo API",
            "records_saved": 0,
            "city_results": [],
            "error": str(e),
        }

    ingestion_runs.insert(0, run)
    del ingestion_runs[10:]


# Local development scheduler for simulating periodic ingestion
scheduler = BackgroundScheduler()
scheduler.add_job(run_ingestion_job, "interval", seconds=10)
scheduler.start()


@app.get("/")
def root():
    return {"service": "hosted-external-data-integration-service-aws"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/dashboard")
def dashboard(request: Request):
    latest_run = ingestion_runs[0] if ingestion_runs else None

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "title": "Hosted External Data Integration Service",
            "status": "Running",
            "source_name": "Open-Meteo API",
            "latest_run": latest_run,
            "run_count": len(ingestion_runs),
            "ingestion_runs": ingestion_runs,
        },
    )