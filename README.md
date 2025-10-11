#  SkiScope
An interactive **Ski Resort Analytics Dashboard** built with **Python, Streamlit, and SQLAlchemy**.  
It visualizes ski resort data including temperature, snowfall, and visitor insights, with future plans to integrate **live global data APIs**.

---

##  Features
✅ Local SQL database for structured resort data  
✅ Data ingestion pipeline using **Pandas**  
✅ Interactive Streamlit dashboard for visual analysis  
✅ Modular project design (`db.py`, `app.py`, `data_ingest.py`)  
✅ Future-ready for live API integrations (Open-Meteo, Ski-Resort.info)

---

##  How It Works
1. **db.py** – initializes and manages the SQLite database  
2. **data_ingest.py** – loads & cleans data into tables  
3. **app.py** – runs the Streamlit web dashboard  
4. **create_tables.sql** – schema for resort data  
5. *(Future)* – `fetch_api_data.py` will pull real data from APIs  

---

##  Planned Enhancements
🔹 Integrate **Open-Meteo API** for live snowfall & temperature tracking  
🔹 Add **Ski-Resort.info API** for global resort metadata  
🔹 Deploy app on **Streamlit Cloud** for public demo access  
🔹 Add filters & trend visualizations (per country, region, or resort)

---

## Tech Stack
| Layer | Tools |
|-------|--------|
| Frontend | Streamlit |
| Backend | Python, Pandas |
| Database | SQLite + SQLAlchemy |
| APIs (Planned) | Open-Meteo, Ski-Resort.info |
| IDE | PyCharm |

---

##  Installation
Clone the repo:
```bash
git clone https://github.com/YOUR_USERNAME/SkiScope.git
cd SkiScope
