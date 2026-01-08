import speech_recognition as sr
from deep_translator import GoogleTranslator
import sys
import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav
import os
import firebase_admin
from firebase_admin import credentials, firestore
import datetime

# Initialize Firebase
if not firebase_admin._apps:
    try:
        cred = credentials.Certificate("service_account.json")
        firebase_admin.initialize_app(cred)
        print("✅ Connected to Firebase Firestore")
    except Exception as e:
        print(f"❌ Firebase Connection Failed: {e}")
        # Proceeding without Firebase (will fail on DB ops but App can start)

def get_db():
    try:
        return firestore.client()
    except:
        return None

# Helper to record audio
def record_audio(filename, duration=5, fs=44100):
    print(f"  🎤 Recording for {duration} seconds...")
    recording = sd.rec(int(duration * fs), samplerate=fs, channels=1, dtype='int16')
    sd.wait()
    wav.write(filename, fs, recording)
    print("  ⏹️ Recording finished.")

def view_history():
    db = get_db()
    if not db:
        print("❌ Database not connected.")
        return

    try:
        docs = db.collection('transactions').order_by('timestamp', direction=firestore.Query.DESCENDING).get()
        
        if not docs:
            print("\n⚠️ History is empty.")
        else:
            print("\n--- Voice Data History (Firestore) ---")
            print(f"{'Hindi':<30} {'English':<30}")
            print("-" * 65)
            for doc in docs:
                data = doc.to_dict()
                hindi = data.get('hindi', data.get('summary_hindi', 'N/A'))
                english = data.get('english', data.get('summary', 'N/A'))
                print(f"{hindi:<30} {english:<30}")
            print("--------------------------")
    except Exception as e:
        print(f"❌ Error fetching history: {e}")

def delete_history():
    print("⚠️ Delete not implemented for safety in Firestore mode.")

def translate_voice(recognizer, lang_choice):
    temp_wav = "temp_recording.wav"
    try:
        # Record Audio
        record_audio(temp_wav, duration=5)

        print("⏳ Processing...")
        
        # Recognize Audio
        with sr.AudioFile(temp_wav) as source:
            audio = recognizer.record(source)
        
        spoken_text = recognizer.recognize_google(audio, language=lang_choice)
        print(f"Detected: {spoken_text}")

        # Translate
        if lang_choice == 'hi':
            hindi_text = spoken_text
            english_text = GoogleTranslator(source='hi', target='en').translate(hindi_text)
        else:
            english_text = spoken_text
            hindi_text = GoogleTranslator(source='en', target='hi').translate(english_text)

        print(f"🇮🇳 Hindi: {hindi_text}")
        print(f"🇺🇸 English: {english_text}")

        # Save to DB (Firestore)
        db = get_db()
        if db:
            db.collection('transactions').add({
                'hindi': hindi_text,
                'english': english_text,
                'summary_hindi': hindi_text, # Using this field to match probable Flutter schema
                'summary': english_text,
                'timestamp': firestore.SERVER_TIMESTAMP,
                'source': 'python_cli'
            })
            print("✅ Saved to Firestore.")
        else:
            print("❌ Not saved (DB offline).")
        
        # Save to file (Append mode)
        with open("output.txt", "a", encoding="utf-8") as f:
            f.write(f"Hindi: {hindi_text}\nEnglish: {english_text}\n\n")

    except sr.UnknownValueError:
        print("❌ Could not understand audio.")
    except sr.RequestError as e:
        print(f"❌ Could not request results; {e}")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        if os.path.exists(temp_wav):
            os.remove(temp_wav)

def get_language_choice():
    while True:
        choice = input("\nSelect Language (hi for Hindi / en for English): ").strip().lower()
        if choice in ['hi', 'en']:
            return choice
        print("❌ Invalid choice. Please enter 'hi' or 'en'.")

def main():
    print("🚀 Starting Voice Translator App (Firebase Enabled)...")
    print("ℹ️  Note: Python 3.14 mode (Using sounddevice + deep-translator)")
    
    # Initialize tools
    recognizer = sr.Recognizer()
    
    # Ask language preference once
    current_lang = get_language_choice()
    
    while True:
        print("\n" + "="*30)
        print(f"Current Language: {'Hindi' if current_lang == 'hi' else 'English'}")
        print("OPTIONS:")
        print("  [Enter] Speak (5s recording)")
        print("  [h]     View History")
        print("  [c]     Change Language")
        print("  [q]     Quit")
        
        command = input(">> ").strip().lower()
        
        if command == 'q':
            print("👋 Exiting application. Bye!")
            break
        elif command == 'h':
            view_history()
        elif command == 'c':
            current_lang = get_language_choice()
        elif command == '':
            translate_voice(recognizer, current_lang)
        else:
            print("❌ Invalid command.")

if __name__ == "__main__":
    main()
