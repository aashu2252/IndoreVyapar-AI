import sys

print("Checking environment...")
try:
    import speech_recognition
    print("✅ speech_recognition is installed.")
except ImportError:
    print("❌ speech_recognition is MISSING.")

try:
    import googletrans
    print("✅ googletrans is installed.")
except ImportError:
    print("❌ googletrans is MISSING.")

try:
    import pyaudio
    print("✅ pyaudio is installed.")
except ImportError:
    print("❌ pyaudio is MISSING.")

try:
    import sqlite3
    print("✅ sqlite3 is installed.")
except ImportError:
    print("❌ sqlite3 is MISSING.")

print("Check complete.")
