"""
Script principal de traitement des candidatures
"""
import asyncio
import sys
from src.logger import app_logger as logger
from src.processor.candidature_processor import candidature_processor


async def main():
    """Point d'entrée principal du script"""
    try:
        logger.info("🚀 Démarrage du traitement SEEG-AI")
        
        # Traitement de toutes les candidatures
        await candidature_processor.process_all_candidatures()
        
        logger.success("✅ Traitement terminé avec succès")
        return 0
        
    except KeyboardInterrupt:
        logger.warning("⚠️ Traitement interrompu par l'utilisateur")
        return 130
        
    except Exception as e:
        logger.error(f"❌ Erreur fatale: {e}")
        logger.exception(e)
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)

