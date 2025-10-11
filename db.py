import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///skiscope.db")
engine = create_engine(DATABASE_URL, future=True)

def init_db():
    sql_path = os.path.join(os.path.dirname(__file__), 'sql', 'create_tables.sql')
    with engine.begin() as conn:
        with open(sql_path, 'r', encoding='utf-8') as f:
            conn.exec_driver_sql(f.read())

def fetch_df(limit=1000):
    import pandas as pd
    with engine.begin() as conn:
        return pd.read_sql(
            text("SELECT * FROM resort_data ORDER BY date ASC LIMIT :lim"),
            conn,
            params={"lim": limit}
        )

if __name__ == "__main__":
    print("Initializing database...")
    init_db()
    print("✅ Database initialized successfully!")