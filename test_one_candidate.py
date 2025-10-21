"""
Script de test pour traiter UN SEUL candidat (vérification du flux)
"""
import asyncio
import json
import sys
from pathlib import Path
from src.logger import app_logger as logger
from src.processor.candidature_processor import candidature_processor


async def test_single_candidate():
    """Teste le traitement d'un seul candidat"""
    try:
        logger.info("🧪 TEST - Traitement d'un seul candidat")
        logger.info("=" * 80)
        
        # Connexion aux services
        await candidature_processor._connect_services()
        
        # Lecture du fichier JSON
        json_file = Path("data/Donnees_candidatures_SEEG.json")
        
        if not json_file.exists():
            logger.error(f"❌ Fichier {json_file} non trouvé")
            return 1
        
        # Charger les données
        with open(json_file, 'r', encoding='utf-8') as f:
            candidats_data = json.load(f)
        
        if not candidats_data or not isinstance(candidats_data, list):
            logger.error("❌ Fichier JSON invalide")
            return 1
        
        logger.info(f"📁 {len(candidats_data)} candidats dans le fichier")
        logger.info("")
        
        # Prendre le PREMIER candidat uniquement
        candidate_data = candidats_data[0]
        
        logger.info("📋 Test avec le premier candidat:")
        logger.info(f"   Nom: {candidate_data.get('first_name')} {candidate_data.get('last_name')}")
        logger.info(f"   Email: {candidate_data.get('email')}")
        logger.info(f"   Poste: {candidate_data.get('job_title')}")
        
        # Vérifier les documents
        if "documents" in candidate_data:
            logger.info(f"   Documents: {len(candidate_data['documents'])} fichiers")
            for doc in candidate_data["documents"]:
                logger.info(f"      - {doc.get('type')}: {doc.get('nom_fichier')}")
        
        logger.info("")
        logger.info("=" * 80)
        logger.info("🚀 Démarrage du traitement...")
        logger.info("=" * 80)
        logger.info("")
        
        # Traiter ce candidat
        await candidature_processor.process_single_candidature_from_data(candidate_data)
        
        logger.info("")
        logger.info("=" * 80)
        logger.success("✅ TEST RÉUSSI !")
        logger.info("=" * 80)
        logger.info("")
        logger.info("Vérification dans MongoDB:")
        logger.info("  - Via API: curl http://localhost:8000/candidatures")
        logger.info("  - Via Shell: ./scripts/mongodb_cli.sh")
        logger.info("  - Via Web: http://localhost:8081")
        
        return 0
        
    except KeyboardInterrupt:
        logger.warning("⚠️ Test interrompu")
        return 130
    except Exception as e:
        logger.error(f"❌ Erreur test: {e}")
        logger.exception(e)
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(test_single_candidate())
    sys.exit(exit_code)

