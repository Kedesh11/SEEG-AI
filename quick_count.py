#!/usr/bin/env python3
"""
Script simple pour afficher rapidement le nombre de candidats
"""
import sys
import os
from pymongo import MongoClient
from dotenv import load_dotenv

def quick_count(connection_string=None):
    """Compte rapide des candidats"""
    try:
        load_dotenv(".env")
        load_dotenv()  # Fallback sur .env
        
        if not connection_string:
            connection_string = os.getenv("COSMOS_CONNECTION_STRING")
        
        if not connection_string:
            print("❌ Connection string manquante")
            return False
        
        client = MongoClient(connection_string, serverSelectionTimeoutMS=5000)
        db = client["SEEG-AI"]
        collection = db["candidats"]
        
        count = collection.count_documents({})
        print(f"📊 Total candidats dans Cosmos DB: {count}")
        
        client.close()
        return True
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

if __name__ == "__main__":
    connection_string = sys.argv[1] if len(sys.argv) > 1 else None
    quick_count(connection_string)
