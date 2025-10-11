CREATE TABLE IF NOT EXISTS resort_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date DATE,
    temperature_c REAL,
    snowfall_cm REAL,
    ticket_price_usd REAL,
    visitors INTEGER
);