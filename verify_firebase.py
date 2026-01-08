import firebase_admin
from firebase_admin import credentials, firestore
import datetime

try:
    print("Initializing Firebase...")
    cred = credentials.Certificate("service_account.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Initialization Successful")

    print("Writing test doc...")
    doc_ref = db.collection('transactions').add({
        'hindi': 'Test Hindi',
        'english': 'Test English',
        'summary': 'Test Summary',
        'timestamp': firestore.SERVER_TIMESTAMP,
        'source': 'test_script'
    })
    print(f"✅ Write Successful. ID: {doc_ref[1].id}")

    print("Reading docs...")
    docs = db.collection('transactions').limit(1).get()
    for doc in docs:
        print(f"✅ Read Successful: {doc.to_dict()}")

except Exception as e:
    print(f"❌ FAILED: {e}")
