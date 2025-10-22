"""
Script de migration DIRECTE des candidatures vers Cosmos DB
Lit depuis data/Donnees_candidatures_SEEG.json et pousse directement vers Azure
Avec traitement OCR complet
"""
import asyncio
import json
import sys
from pathlib import Path
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError
from dotenv import load_dotenv
import os

# Import des modules SEEG-AI
from src.logger import app_logger as logger
from src.processor.candidature_processor import candidature_processor
from src.config import settings


async def migrate_direct_to_cosmos(cosmos_connection_string: str):
    """
    Migration directe depuis JSON source vers Cosmos DB
    
    Args:
        cosmos_connection_string: Connection string Cosmos DB
    """
    try:
        logger.info("=" * 80)
        logger.info("MIGRATION DIRECTE VERS COSMOS DB AZURE")
        logger.info("=" * 80)
        
        # 1. Vérifier le fichier source
        json_file = Path("data/Donnees_candidatures_SEEG.json")
        if not json_file.exists():
            logger.error(f"❌ Fichier {json_file} introuvable")
            return False
        
        # 2. Charger les données
        logger.info(f"📁 Lecture du fichier source: {json_file}")
        with open(json_file, 'r', encoding='utf-8') as f:
            candidats_data = json.load(f)
        
        total_candidats = len(candidats_data)
        logger.info(f"✓ {total_candidats} candidats trouvés dans le fichier\n")
        
        # 3. Connexion à Cosmos DB
        logger.info("🔌 Connexion à Cosmos DB Azure...")
        client = MongoClient(
            cosmos_connection_string,
            serverSelectionTimeoutMS=10000,
            connectTimeoutMS=10000
        )
        db = client["SEEG-AI"]
        collection = db["candidats"]
        
        # Test de connexion
        collection.find_one()
        logger.success("✓ Connecté à Cosmos DB Azure\n")
        
        # Compter les documents existants
        existing_count = collection.count_documents({})
        logger.info(f"📊 Documents existants dans Cosmos DB: {existing_count}\n")
        
        # 4. Connexion aux services (Azure OCR, Supabase)
        logger.info("🔌 Connexion aux services Azure OCR et Supabase...")
        await candidature_processor._connect_services()
        logger.info("")
        
        # 5. Temporairement rediriger mongodb_client vers Cosmos DB
        from src.database.mongodb_client import mongodb_client
        
        # Sauvegarder l'ancienne connexion
        old_client = mongodb_client.client
        old_collection = mongodb_client.collection
        
        # Remplacer par Cosmos DB
        mongodb_client.client = client
        mongodb_client.collection = collection
        
        logger.info("=" * 80)
        logger.info(f"TRAITEMENT DE {total_candidats} CANDIDATURES")
        logger.info("=" * 80)
        logger.info("")
        
        # 6. Traiter chaque candidature
        processed_count = 0
        duplicates_count = 0
        failed_count = 0
        
        for idx, candidate_data in enumerate(candidats_data, 1):
            try:
                application_id = candidate_data.get("application_id")
                first_name = candidate_data.get("first_name", "")
                last_name = candidate_data.get("last_name", "")
                
                logger.info(f"\n{'─' * 80}")
                logger.info(f"[{idx}/{total_candidats}] {first_name} {last_name}")
                logger.info(f"{'─' * 80}")
                
                # Vérifier si déjà existe
                if application_id:
                    existing = collection.find_one({"application_id": application_id})
                    if existing:
                        logger.warning(f"⚠️  Candidat déjà présent dans Cosmos DB (ignoré)")
                        duplicates_count += 1
                        continue
                
                # Traiter la candidature (téléchargement + OCR + sauvegarde)
                await candidature_processor.process_single_candidature_from_data(
                    candidate_data
                )
                
                processed_count += 1
                logger.success(f"✓ Candidat {idx}/{total_candidats} traité avec succès")
                
            except Exception as e:
                failed_count += 1
                logger.error(f"❌ Erreur candidat {idx}: {e}")
                continue
        
        # 7. Restaurer l'ancienne connexion
        mongodb_client.client = old_client
        mongodb_client.collection = old_collection
        
        # 8. Vérification finale
        logger.info("\n" + "=" * 80)
        logger.info("VÉRIFICATION FINALE")
        logger.info("=" * 80)
        
        final_count = collection.count_documents({})
        new_documents = final_count - existing_count
        
        logger.info(f"\n📊 Documents dans Cosmos DB:")
        logger.info(f"   Avant:            {existing_count}")
        logger.info(f"   Après:            {final_count}")
        logger.info(f"   Nouveaux ajoutés: {new_documents}")
        
        logger.info(f"\n📈 Résultat du traitement:")
        logger.info(f"   Total traité:     {total_candidats}")
        logger.info(f"   Succès:           {processed_count}")
        logger.info(f"   Duplicata ignorés: {duplicates_count}")
        logger.info(f"   Échecs:           {failed_count}")
        
        success_rate = (processed_count / total_candidats * 100) if total_candidats > 0 else 0
        logger.info(f"   Taux de succès:   {success_rate:.1f}%")
        
        # 9. Afficher quelques exemples
        if final_count > 0:
            logger.info(f"\n📋 Exemples de candidatures dans Cosmos DB:")
            for i, doc in enumerate(collection.find().limit(5), 1):
                nom = f"{doc.get('first_name', '')} {doc.get('last_name', '')}"
                poste = doc.get('offre', {}).get('intitule', 'N/A')
                logger.info(f"   {i}. {nom} - {poste}")
        
        # Fermer la connexion
        client.close()
        
        logger.info("\n" + "=" * 80)
        if failed_count == 0:
            logger.success("✅ MIGRATION 100% RÉUSSIE !")
        else:
            logger.warning(f"⚠️  MIGRATION PARTIELLE ({processed_count}/{total_candidats})")
        logger.info("=" * 80)
        logger.info("")
        
        return failed_count == 0
        
    except KeyboardInterrupt:
        logger.warning("\n⚠️  Migration interrompue par l'utilisateur")
        return False
        
    except Exception as e:
        logger.error(f"\n❌ Erreur fatale: {e}")
        logger.exception(e)
        return False


def main():
    """Point d'entrée principal"""
    # Charger les variables d'environnement
    load_dotenv()
    
    # Connection string depuis ligne de commande ou .env
    connection_string = None
    
    if len(sys.argv) > 1:
        connection_string = sys.argv[1]
    else:
        connection_string = os.getenv("COSMOS_CONNECTION_STRING")
    
    if not connection_string:
        print("\n❌ Erreur: Connection string Cosmos DB non fournie")
        print("\nUtilisation:")
        print("  python migrate_direct_to_cosmos.py <cosmos_connection_string>")
        print("\nOu définir COSMOS_CONNECTION_STRING dans .env")
        print("\nPour récupérer la connection string:")
        print("  az cosmosdb keys list --name seeg-ai --resource-group seeg-rg --type connection-strings")
        print()
        sys.exit(1)
    
    # Exécuter la migration
    success = asyncio.run(migrate_direct_to_cosmos(connection_string))
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

