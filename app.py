import os
import pandas as pd
import streamlit as st
import matplotlib.pyplot as plt
from joblib import load
from db import fetch_df


st.title("🎿 SkiScope — Visitor Predictor")
MODEL_PATH = 'models/model.pkl'
model = load(MODEL_PATH) if os.path.exists(MODEL_PATH) else None


col1, col2 = st.columns(2)
with col1:
    temperature_c = st.slider("Average Temperature (°C)", -25, 10, -4)
snowfall_cm = st.slider("Snowfall (cm)", 0, 60, 20)
with col2:
    ticket_price_usd = st.slider("Ticket Price (USD)", 50, 250, 129)


if model:
    pred = int(model.predict([[temperature_c, snowfall_cm, ticket_price_usd]])[0])
    st.subheader(f"Predicted Visitors: {pred:,}")
else:
    st.warning("Train the model first with train_model.py.")


df = fetch_df(limit=365)
if not df.empty:
    st.dataframe(df.tail(20))
    plt.figure()
    plt.plot(pd.to_datetime(df['date']), df['visitors'])
    st.pyplot(plt.gcf())
else:
    st.info("No data yet. Run data_ingest.py.")