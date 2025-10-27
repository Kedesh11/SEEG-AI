#!/usr/bin/env python3
"""
Script pour vérifier le nombre de candidats dans Cosmos DB
"""
import sys
import os
from pymongo import MongoClient
from dotenv import load_dotenv
from src.logger import app_logger as logger

def check_candidats_count(connection_string=None):
    """
    Vérifie le nombre de candidats dans Cosmos DB
    
    Args:
        connection_string: Connection string Cosmos DB (optionnel)
    """
    try:
        # Charger les variables d'environnement (.env en priorité)
        load_dotenv(".env")
        load_dotenv()  # Fallback sur .env
        
        # Récupérer la connection string
        if not connection_string:
            connection_string = os.getenv("COSMOS_CONNECTION_STRING")
        
        if not connection_string:
            logger.error("❌ Connection string Cosmos DB non fournie")
            logger.info("Utilisation:")
            logger.info("  python check_candidats_count.py <cosmos_connection_string>")
            logger.info("Ou définir COSMOS_CONNECTION_STRING dans .env")
            return False
        
        logger.info("🔌 Connexion à Cosmos DB...")
        
        # Connexion à Cosmos DB
        client = MongoClient(
            connection_string,
            serverSelectionTimeoutMS=10000,
            connectTimeoutMS=10000
        )
        
        db = client["SEEG-AI"]
        collection = db["candidats"]
        
        # Test de connexion
        collection.find_one()
        logger.success("✓ Connecté à Cosmos DB")
        
        # Compter les candidats
        total_count = collection.count_documents({})
        
        logger.info("=" * 60)
        logger.info("📊 STATISTIQUES CANDIDATS COSMOS DB")
        logger.info("=" * 60)
        logger.info(f"📈 Total candidats: {total_count}")
        
        # Statistiques par offre
        pipeline = [
            {"$group": {
                "_id": "$offre.intitule",
                "count": {"$sum": 1}
            }},
            {"$sort": {"count": -1}},
            {"$limit": 10}
        ]
        
        offre_stats = list(collection.aggregate(pipeline))
        
        if offre_stats:
            logger.info("\n📋 Top 10 des offres:")
            for i, stat in enumerate(offre_stats, 1):
                offre = stat["_id"] or "Non spécifié"
                count = stat["count"]
                logger.info(f"   {i:2d}. {offre}: {count} candidats")
        
        # Statistiques par statut
        pipeline_status = [
            {"$group": {
                "_id": "$statut",
                "count": {"$sum": 1}
            }},
            {"$sort": {"count": -1}}
        ]
        
        status_stats = list(collection.aggregate(pipeline_status))
        
        if status_stats:
            logger.info("\n📊 Répartition par statut:")
            for stat in status_stats:
                status = stat["_id"] or "Non spécifié"
                count = stat["count"]
                logger.info(f"   • {status}: {count} candidats")
        
        # Derniers candidats ajoutés
        logger.info("\n🆕 5 derniers candidats ajoutés:")
        recent_candidats = list(collection.find().sort("_id", -1).limit(5))
        
        for i, candidat in enumerate(recent_candidats, 1):
            nom = f"{candidat.get('first_name', '')} {candidat.get('last_name', '')}"
            offre = candidat.get('offre', {}).get('intitule', 'N/A')
            logger.info(f"   {i}. {nom} - {offre}")
        
        # Vérifier les candidats avec documents OCR
        candidats_avec_ocr = collection.count_documents({
            "documents": {"$exists": True, "$ne": None}
        })
        
        candidats_sans_ocr = total_count - candidats_avec_ocr
        
        logger.info(f"\n📄 Documents OCR:")
        logger.info(f"   • Avec OCR: {candidats_avec_ocr} candidats")
        logger.info(f"   • Sans OCR: {candidats_sans_ocr} candidats")
        
        # Fermer la connexion
        client.close()
        
        logger.info("=" * 60)
        logger.success(f"✅ Vérification terminée: {total_count} candidats trouvés")
        logger.info("=" * 60)
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur: {e}")
        return False

def main():
    """Point d'entrée principal"""
    connection_string = None
    
    if len(sys.argv) > 1:
        connection_string = sys.argv[1]
    
    success = check_candidats_count(connection_string)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
