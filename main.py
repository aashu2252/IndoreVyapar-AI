import speech_recognition as sr
from googletrans import Translator
import sqlite3
import sys

def setup_db():
    conn = sqlite3.connect("voice_data.db")
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

def get_db_connection():
    return sqlite3.connect("voice_data.db")

def view_history():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM voice_text")
        rows = cursor.fetchall()
        
        if not rows:
            print("\n⚠️ History is empty.")
        else:
            print("\n--- Voice Data History ---")
            print(f"{'ID':<5} {'Hindi':<30} {'English':<30}")
            print("-" * 65)
            for row in rows:
                print(f"{row[0]:<5} {row[1]:<30} {row[2]:<30}")
            print("--------------------------")
        conn.close()
    except Exception as e:
        print(f"❌ Error fetching history: {e}")

def delete_history():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM voice_text")
        conn.commit()
        conn.close()
        print("\n🗑️  History deleted successfully.")
    except Exception as e:
        print(f"❌ Error deleting history: {e}")

def translate_voice(recognizer, translator, lang_choice):
    try:
        with sr.Microphone() as source:
            print(f"\n🎤 Listening... ({'Hindi' if lang_choice=='hi' else 'English'})")
            # Adjust for ambient noise for better accuracy
            recognizer.adjust_for_ambient_noise(source, duration=0.5)
            audio = recognizer.listen(source)

        print("⏳ Processing...")
        spoken_text = recognizer.recognize_google(audio, language=lang_choice)
        print(f"Detected: {spoken_text}")

        # Translate
        if lang_choice == 'hi':
            hindi_text = spoken_text
            english_text = translator.translate(hindi_text, src='hi', dest='en').text
        else:
            english_text = spoken_text
            hindi_text = translator.translate(english_text, src='en', dest='hi').text

        print(f"🇮🇳 Hindi: {hindi_text}")
        print(f"🇺🇸 English: {english_text}")

        # Save to DB
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO voice_text (hindi, english) VALUES (?, ?)",
            (hindi_text, english_text)
        )
        conn.commit()
        conn.close()
        
        # Save to file (Append mode)
        with open("output.txt", "a", encoding="utf-8") as f:
            f.write(f"Hindi: {hindi_text}\nEnglish: {english_text}\n\n")

        print("✅ Saved to database.")

    except sr.UnknownValueError:
        print("❌ Could not understand audio.")
    except sr.RequestError as e:
        print(f"❌ Could not request results; {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

def get_language_choice():
    while True:
        choice = input("\nSelect Language (hi for Hindi / en for English): ").strip().lower()
        if choice in ['hi', 'en']:
            return choice
        print("❌ Invalid choice. Please enter 'hi' or 'en'.")

def main():
    print("🚀 Starting Voice Translator App...")
    setup_db()
    
    # Initialize tools
    recognizer = sr.Recognizer()
    translator = Translator()
    
    # Ask language preference once
    current_lang = get_language_choice()
    
    while True:
        print("\n" + "="*30)
        print(f"Current Language: {'Hindi' if current_lang == 'hi' else 'English'}")
        print("OPTIONS:")
        print("  [Enter] Speak")
        print("  [h]     View History")
        print("  [d]     Delete History")
        print("  [c]     Change Language")
        print("  [q]     Quit")
        
        command = input(">> ").strip().lower()
        
        if command == 'q':
            print("👋 Exiting application. Bye!")
            break
        elif command == 'h':
            view_history()
        elif command == 'd':
            delete_history()
        elif command == 'c':
            current_lang = get_language_choice()
        elif command == '':
            translate_voice(recognizer, translator, current_lang)
        else:
            print("❌ Invalid command.")

if __name__ == "__main__":
    main()
