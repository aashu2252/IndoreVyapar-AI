import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav
import speech_recognition as sr
from deep_translator import GoogleTranslator
import os

print("1. Testing SoundDevice (Recording 3 seconds)...")
try:
    fs = 44100
    duration = 3
    recording = sd.rec(int(duration * fs), samplerate=fs, channels=1, dtype='int16')
    sd.wait()
    print("Recording complete.")
    wav.write("test_audio.wav", fs, recording)
    print("Saved test_audio.wav")
except Exception as e:
    print(f"FAILED SoundDevice: {e}")

print("\n2. Testing SpeechRecognition with file...")
try:
    r = sr.Recognizer()
    with sr.AudioFile("test_audio.wav") as source:
        audio = r.record(source)
    # Don't actually recognize, just check if it loaded audio ok.
    # Verification of recognition requires internet and valid audio.
    # We'll just print audio duration
    print(f"Audio loaded. Duration: {len(audio.frame_data)/audio.sample_rate/audio.sample_width} sec approx")
except Exception as e:
    print(f"FAILED SpeechRecognition: {e}")

print("\n3. Testing DeepTranslator...")
try:
    translated = GoogleTranslator(source='en', target='hi').translate("Hello world")
    print(f"Translated 'Hello world' to: {translated}")
    if not translated:
        print("FAILED DeepTranslator: Empty result")
except Exception as e:
    print(f"FAILED DeepTranslator: {e}")
