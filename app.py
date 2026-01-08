from flask import Flask, render_template, jsonify, request
import speech_recognition as sr
from googletrans import Translator
import sqlite3
import os

app = Flask(__name__)

# Initialize tools
recognizer = sr.Recognizer()
translator = Translator()

def get_db_connection():
    conn = sqlite3.connect("voice_data.db")
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    conn.execute("""
    CREATE TABLE IF NOT EXISTS voice_text (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hindi TEXT,
        english TEXT
    )
    """)
    conn.commit()
    conn.close()

# Ensure DB is ready
init_db()

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/api/process_voice', methods=['POST'])
def process_voice():
    try:
        data = request.json
        lang_choice = data.get('language', 'en')
        
        # Capture Voice (Server-side)
        with sr.Microphone() as source:
            recognizer.adjust_for_ambient_noise(source, duration=0.2)
            print("Listening...")
            audio = recognizer.listen(source, timeout=10, phrase_time_limit=10)

        # Speech to Text
        spoken_text = recognizer.recognize_google(audio, language=lang_choice)
        
        # Translate
        if lang_choice == 'hi':
            hindi_text = spoken_text
            english_text = translator.translate(hindi_text, src='hi', dest='en').text
        else:
            english_text = spoken_text
            hindi_text = translator.translate(english_text, src='en', dest='hi').text

        # Save to DB
        conn = get_db_connection()
        conn.execute(
            "INSERT INTO voice_text (hindi, english) VALUES (?, ?)",
            (hindi_text, english_text)
        )
        conn.commit()
        conn.close()

        # Save to file
        with open("output.txt", "a", encoding="utf-8") as f:
            f.write(f"Hindi: {hindi_text}\nEnglish: {english_text}\n\n")

        return jsonify({
            'status': 'success',
            'spoken': spoken_text,
            'hindi': hindi_text,
            'english': english_text
        })

    except sr.WaitTimeoutError:
         return jsonify({'status': 'error', 'message': 'Listening timed out. No speech detected.'})
    except sr.UnknownValueError:
        return jsonify({'status': 'error', 'message': 'Could not understand audio.'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/history', methods=['GET'])
def get_history():
    try:
        conn = get_db_connection()
        rows = conn.execute("SELECT * FROM voice_text ORDER BY id DESC").fetchall()
        conn.close()
        
        history = [{'id': row['id'], 'hindi': row['hindi'], 'english': row['english']} for row in rows]
        return jsonify({'status': 'success', 'history': history})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/delete_history', methods=['POST'])
def delete_history_api():
    try:
        conn = get_db_connection()
        conn.execute("DELETE FROM voice_text")
        conn.commit()
        conn.close()
        return jsonify({'status': 'success', 'message': 'History deleted'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    app.run(debug=True)
