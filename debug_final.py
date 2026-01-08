import sys

def log(msg):
    with open("debug_output_final.txt", "a") as f:
        f.write(msg + "\n")

try:
    with open("debug_output_final.txt", "w") as f: f.write("") # check clear
    log(f"Python: {sys.version}")
    
    try:
        import flask
        log(f"Flask: OK ({flask.__version__})")
    except ImportError as e:
        log(f"Flask: FAILED ({e})")

    try:
        import speech_recognition
        log(f"SpeechRecognition: OK ({speech_recognition.__version__})")
    except ImportError as e:
        log(f"SpeechRecognition: FAILED ({e})")
        
    try:
        import googletrans
        log("googletrans: OK")
    except ImportError as e:
        log(f"googletrans: FAILED ({e})")

    try:
        import pyaudio
        log("pyaudio: OK")
    except ImportError as e:
        log(f"pyaudio: FAILED (Expected on 3.14)")

except Exception as e:
    log(f"Fatal: {e}")
