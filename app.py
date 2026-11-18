import math
import os
import pandas as pd
import streamlit as st
from sqlalchemy import create_engine, inspect, text
import plotly.express as px
from datetime import datetime
from dotenv import load_dotenv
import subprocess
import sys

# --- Load environment variables (a .env file is optional; real env vars win) ---
load_dotenv()
DATABASE_URL = os.environ["DATABASE_URL"]

# --- Connect to DB ---
engine = create_engine(DATABASE_URL)

# --- Page setup ---
st.set_page_config(page_title="SkiScope Dashboard 🏔️", layout="wide")
st.title("🎿 SkiScope – Live Resort Weather Dashboard")

# --- Data Loader ---
@st.cache_data(ttl=600)
def load_data():
    # On a fresh database the table doesn't exist until the first "Update Data"
    if not inspect(engine).has_table("resort_data"):
        return pd.DataFrame()
    with engine.begin() as conn:
        df = pd.read_sql(text("SELECT * FROM resort_data ORDER BY last_updated DESC"), conn)
    return df

# --- Refresh data ---
def refresh_data():
    with st.spinner("Fetching latest data..."):
        subprocess.run([sys.executable, "fetch_api_data.py"], check=True)
    st.success("✅ Data updated successfully! Please click 'Reload Data' below.")

# --- Sidebar controls ---
st.sidebar.header("⚙️ Controls")
if st.sidebar.button("🔄 Update Data"):
    refresh_data()

df = load_data()

if st.sidebar.button("♻️ Reload Data"):
    st.cache_data.clear()
    df = load_data()

if df.empty:
    st.warning("⚠️ No data found in database. Click 'Update Data' in the sidebar, then 'Reload Data'.")
    st.stop()

# --- Filters ---
st.sidebar.subheader("🎚️ Filters")
# Handle cases where snow_depth or windspd_kmh are all 0
snow_max = max(1, math.ceil(df["snow_depth"].max()))  # ceil so the top resort isn't filtered out
wind_max = max(1, math.ceil(df["windspd_kmh"].max()))

min_snow = st.sidebar.slider("Minimum Snow Depth (cm)", 0, snow_max, 0)
max_wind = st.sidebar.slider("Maximum Wind Speed (km/h)", 0, wind_max, wind_max)

filtered = df[(df["snow_depth"] >= min_snow) & (df["windspd_kmh"] <= max_wind)]

# --- Resort Cards ---
st.subheader(f"🏔️ Resort Conditions (showing {len(filtered)} resorts)")
cols = st.columns(3)
for i, (_, row) in enumerate(filtered.iterrows()):
    with cols[i % 3]:
        st.markdown(f"""
        **{row['resort_name']}**
        - 🌡️ Temp: `{row['temp_c']}°C`
        - ❄️ Snow Depth: `{row['snow_depth']} cm`
        - 💨 Wind: `{row['windspd_kmh']} km/h`
        - 🕒 Updated: `{row['last_updated']}`
        """)

# --- Charts ---
st.divider()
st.subheader("📊 Visual Insights")

col1, col2 = st.columns(2)

with col1:
    fig1 = px.bar(filtered, x="resort_name", y="snow_depth",
                  color="resort_name", title="Snow Depth by Resort (cm)")
    st.plotly_chart(fig1, use_container_width=True)

with col2:
    fig2 = px.bar(filtered, x="resort_name", y="temp_c",
                  color="resort_name", title="Temperature by Resort (°C)")
    st.plotly_chart(fig2, use_container_width=True)

# --- Footer ---
st.markdown("---")
st.caption(f"Data last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | Powered by Open-Meteo 🌨️")
