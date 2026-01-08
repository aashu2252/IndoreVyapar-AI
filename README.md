# Voice Translator Project

This project allows you to speak in Hindi or English, translates the speech to the other language, and creates a record in an SQLite database.

## Project Structure

*   `main.py`: The main application script. Run this to use the translator.
*   `setup_db.py`: A helper script to create the `voice_data.db` database.
*   `view_db.py`: A helper script to view the contents of the database.
*   `requirements.txt`: The list of Python libraries required.

## Installation

1.  Make sure you have Python installed.
2.  Install the required dependencies:
    ```bash
    pip install -r requirements.txt
    ```

## Usage

1.  **Run the Translator:**
    ```bash
    python main.py
    ```
    Follow the on-screen prompts. You will be asked to choose a language (Hindi or English) and then speak.

2.  **View Saved Data:**
    ```bash
    python view_db.py
    ```
    This will print the contents of the database to the console.

## Troubleshooting

*   **Microphone Issues:** Ensure your microphone is set as the default recording device.
*   **PyAudio Errors:** If you have trouble installing PyAudio, you might need to install additional system tools (like `portaudio` on Mac/Linux) or use a pre-built wheel on Windows.
