import os
import requests
import pandas as pd
from datetime import datetime
from dotenv import load_dotenv
from sqlalchemy import create_engine

# --- Load environment variables ---
load_dotenv()  # a .env file is optional; real env vars win

DATABASE_URL = os.environ["DATABASE_URL"]

# --- Connect to PostgreSQL ---
engine = create_engine(DATABASE_URL)
print("✅ Database engine ready")

# --- Sample U.S. resorts for testing ---
RESORTS = [
    {"resort_name": "Aspen Snowmass", "latitude": 39.2089, "longitude": -106.9498},
    {"resort_name": "Vail", "latitude": 39.6403, "longitude": -106.3742},
    {"resort_name": "Park City", "latitude": 40.6461, "longitude": -111.4980},
    {"resort_name": "Jackson Hole", "latitude": 43.5875, "longitude": -110.8271},
    {"resort_name": "Killington", "latitude": 43.6195, "longitude": -72.8205}
]

def get_weather(lat, lon):
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": "temperature_2m,snowfall,snow_depth,wind_speed_10m",
        "forecast_days": 1,
        "timezone": "auto"
    }
    try:
        r = requests.get(url, params=params, timeout=20)
        r.raise_for_status()
        d = r.json()
        temp = d["hourly"]["temperature_2m"][0]
        snow = d["hourly"]["snowfall"][0]
        depth = round(d["hourly"]["snow_depth"][0] * 100, 1)  # API gives metres; dashboard shows cm
        wind = d["hourly"]["wind_speed_10m"][0]
        return {
            "temp_c": temp,
            "fresh_snow_cm": snow,
            "snow_depth": depth,
            "windspd_kmh": wind,
            "last_updated": datetime.now().isoformat()
        }
    except Exception as e:
        print(f"⚠️ Failed weather fetch for {lat},{lon} -> {e}")
        return {}


# --- Build dataset and save to DB ---
def build_and_save():
    results = []
    for r in RESORTS:
        wx = get_weather(r["latitude"], r["longitude"])
        if wx:
            results.append({**r, **wx})
    df = pd.DataFrame(results)
    if not df.empty:
        df.to_sql("resort_data", engine, if_exists="replace", index=False)
        print(f"💾 Saved {len(df)} resorts to database.")
    else:
        print("⚠️ No data saved.")
    return df

if __name__ == "__main__":
    df = build_and_save()
    print("✅ Data pipeline complete.")
    print(df.head())
