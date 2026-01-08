import sys

def log(msg):
    with open("debug_output.txt", "a") as f:
        f.write(msg + "\n")

try:
    log("Starting checks...")
    
    try:
        import flask
        log(f"Flask imported: {flask.__version__}")
    except ImportError as e:
        log(f"Flask failed: {e}")

    try:
        import speech_recognition
        log(f"SpeechRecognition imported: {speech_recognition.__version__}")
    except ImportError as e:
        log(f"SpeechRecognition failed: {e}")
        
    try:
        import googletrans
        log("googletrans imported")
    except ImportError as e:
        log(f"googletrans failed: {e}")

    try:
        import pyaudio
        log("pyaudio imported")
    except ImportError as e:
        log(f"pyaudio failed: {e}")

    log("Checks finished.")

except Exception as e:
    with open("debug_output.txt", "a") as f:
        f.write(f"Fatal error: {e}\n")
