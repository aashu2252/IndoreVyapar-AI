import sqlite3

# Connect to database
conn = sqlite3.connect("voice_data.db")
cursor = conn.cursor()

# Fetch data
try:
    # Check if table exists first
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='voice_text'")
    if not cursor.fetchone():
        print("Database is connected but table 'voice_text' does not exist yet.")
    else:
        # Read data
        cursor.execute("SELECT * FROM voice_text")
        rows = cursor.fetchall()
        
        if not rows:
            print("Database is connected, but the table is empty.")
        else:
            print("\n--- Voice Data Database Content ---")
            print(f"{'ID':<5} {'Hindi':<30} {'English':<30}")
            print("-" * 65)
            for row in rows:
                print(f"{row[0]:<5} {row[1]:<30} {row[2]:<30}")
            print("-----------------------------------")
            
except Exception as e:
    print(f"Error reading database: {e}")

conn.close()

