from flask import Flask, render_template, jsonify, request
import speech_recognition as sr
from deep_translator import GoogleTranslator
import os
import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav
import firebase_admin
from firebase_admin import credentials, firestore

app = Flask(__name__)

# Initialize Firebase
if not firebase_admin._apps:
    try:
        cred = credentials.Certificate("service_account.json")
        firebase_admin.initialize_app(cred)
        print("✅ Connected to Firebase Firestore")
    except Exception as e:
        print(f"❌ Firebase Connection Failed: {e}")

def get_db():
    try:
        return firestore.client()
    except:
        return None

# Initialize tools
recognizer = sr.Recognizer()

# Helper to record audio
def record_audio(filename, duration=5, fs=44100):
    print(f"Listening for {duration} seconds (Server Side)...")
    recording = sd.rec(int(duration * fs), samplerate=fs, channels=1, dtype='int16')
    sd.wait()
    wav.write(filename, fs, recording)
    print("Recording finished.")

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/api/process_voice', methods=['POST'])
def process_voice():
    temp_wav = "server_temp.wav"
    try:
        data = request.json
        lang_choice = data.get('language', 'en')
        
        # Capture Voice (Server-side)
        record_audio(temp_wav, duration=5)

        # Speech to Text
        with sr.AudioFile(temp_wav) as source:
            audio = recognizer.record(source)
            
        spoken_text = recognizer.recognize_google(audio, language=lang_choice)
        
        # Translate
        if lang_choice == 'hi':
            hindi_text = spoken_text
            english_text = GoogleTranslator(source='hi', target='en').translate(hindi_text)
        else:
            english_text = spoken_text
            hindi_text = GoogleTranslator(source='en', target='hi').translate(english_text)

        # Save to DB (Firestore)
        db = get_db()
        if db:
            db.collection('transactions').add({
                'hindi': hindi_text,
                'english': english_text,
                'summary_hindi': hindi_text,
                'summary': english_text,
                'timestamp': firestore.SERVER_TIMESTAMP,
                'source': 'python_web'
            })
        
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
    finally:
        if os.path.exists(temp_wav):
            os.remove(temp_wav)

@app.route('/api/history', methods=['GET'])
def get_history():
    try:
        db = get_db()
        if not db:
             return jsonify({'status': 'error', 'message': 'Database not connected'})

        docs = db.collection('transactions').order_by('timestamp', direction=firestore.Query.DESCENDING).get()
        
        history = []
        for doc in docs:
            data = doc.to_dict()
            history.append({
                'id': doc.id,
                'hindi': data.get('hindi', data.get('summary_hindi')),
                'english': data.get('english', data.get('summary'))
            })
        return jsonify({'status': 'success', 'history': history})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/delete_history', methods=['POST'])
def delete_history_api():
    return jsonify({'status': 'error', 'message': 'Delete Not Supported in Firestore Mode'})

if __name__ == '__main__':
    app.run(debug=True)
