import sqlite3
import os

db_file = "voice_data.db"

# Database setup
conn = sqlite3.connect(db_file)
cursor = conn.cursor()
cursor.execute("""
CREATE TABLE IF NOT EXISTS voice_text (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hindi TEXT,
    english TEXT
)
""")
conn.commit()
conn.close()

print(f"Database '{db_file}' successfully created/verified at: {os.path.abspath(db_file)}")
