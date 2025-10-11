import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import r2_score, mean_absolute_error
from joblib import dump
from db import fetch_df


if __name__ == "__main__":
df = fetch_df(limit=100000)
if df.empty:
print("No data found. Run data_ingest.py first.")
raise SystemExit(1)


X = df[['temperature_c', 'snowfall_cm', 'ticket_price_usd']]
y = df['visitors']


X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model = RandomForestRegressor(n_estimators=300, random_state=42)
model.fit(X_train, y_train)


preds = model.predict(X_test)
print("R2:", round(r2_score(y_test, preds), 3))
print("MAE:", round(mean_absolute_error(y_test, preds), 1))


dump(model, 'models/model.pkl')
print("Saved models/model.pkl")