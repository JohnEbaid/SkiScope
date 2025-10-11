from db import init_db, engine
from sqlalchemy import text
import pandas as pd
from datetime import datetime, timedelta

# Function to insert sample data
def insert_sample_data():
    start_date = datetime.now() - timedelta(days=30)
    data = []
    for i in range(30):
        data.append({
            "date": (start_date + timedelta(days=i)).date(),
            "temperature_c": round(0 + i * 0.3, 2),
            "snowfall_cm": round(5 + i * 0.5, 2),
            "ticket_price_usd": 80 + i,
            "visitors": 100 + i * 10
        })
    df = pd.DataFrame(data)
    with engine.begin() as conn:
        df.to_sql("resort_data", conn, if_exists="append", index=False)

# Run the script
if __name__ == "__main__":
    init_db()
    insert_sample_data()
    print("✅ Data ingested successfully!")
