############################################
# Weather code mappings
############################################
# Weather code mappings based on Open-Meteo / WMO weather
# interpretation codes. These are used to enrich raw API data
# into more readable dashboard-friendly values.
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


############################################
# Helper functions
############################################
# Convert wind direction in degrees into a simple compass label.
# Example: 0 -> N, 90 -> E, 180 -> S, 270 -> W
def wind_direction_to_compass(deg):
    directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    index = round(deg / 45) % 8
    return directions[index]


# Convert wind direction in degrees into a directional arrow.
# This is used to make dashboard output easier to scan visually.
def wind_arrow(deg):
    arrows = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
    index = round(deg / 45) % 8
    return arrows[index]