"""
Client Supabase pour récupérer les URLs des documents
"""
import httpx
import aiohttp
from typing import Optional, Dict, Any
from pathlib import Path
from src.config import settings
from src.logger import app_logger as logger


class SupabaseConfig:
    """Configuration Supabase simple"""
    def __init__(self):
        self.supabase_url = settings.supabase_url


class SupabaseClient:
    """Client pour interagir avec Supabase"""
    
    def __init__(self):
        self.client = SupabaseConfig()
    
    def connect(self):
        """Initialise la connexion Supabase"""
        try:
            logger.info("Configuration Supabase...")
            logger.success("✓ Configuration Supabase prête")
            
        except Exception as e:
            logger.error(f"Erreur configuration Supabase: {e}")
            raise
    
    async def download_file(self, url: str, destination: Path) -> bool:
        """
        Télécharge un fichier depuis une URL Supabase
        
        Args:
            url: URL du fichier à télécharger
            destination: Chemin de destination local
            
        Returns:
            True si le téléchargement a réussi
        """
        try:
            logger.info(f"Téléchargement: {url}")
            
            # Créer le répertoire parent si nécessaire
            destination.parent.mkdir(parents=True, exist_ok=True)
            
            # Téléchargement asynchrone avec aiohttp
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=aiohttp.ClientTimeout(total=60)) as response:
                    response.raise_for_status()
                    
                    # Écriture du fichier
                    with open(destination, 'wb') as f:
                        async for chunk in response.content.iter_chunked(8192):
                            f.write(chunk)
            
            logger.success(f"✓ Fichier téléchargé: {destination.name}")
            return True
            
        except Exception as e:
            logger.error(f"Erreur téléchargement {url}: {e}")
            return False
    
    def get_document_urls_from_candidate(
        self,
        candidate_data: Dict[str, Any]
    ) -> Dict[str, str]:
        """
        Extrait les URLs des documents d'un candidat depuis les données JSON
        
        Args:
            candidate_data: Données JSON du candidat
            
        Returns:
            Dictionnaire avec les URLs complètes des documents
        """
        urls = {}
        
        # Le bucket Supabase pour les documents candidats
        BUCKET_NAME = settings.supabase_bucket_name
        
        # Les documents sont dans un tableau avec type, nom_fichier, url (chemin relatif)
        if "documents" in candidate_data and isinstance(candidate_data["documents"], list):
            for doc in candidate_data["documents"]:
                doc_type = doc.get("type")
                relative_url = doc.get("url")
                
                if not doc_type or not relative_url:
                    continue
                
                # Construire l'URL complète Supabase
                # Format: https://{project_id}.supabase.co/storage/v1/object/public/{bucket}/{path}
                full_url = f"{self.client.supabase_url}/storage/v1/object/public/{BUCKET_NAME}/{relative_url}"
                
                # Mapper les types anglais vers les clés attendues
                if doc_type == "cv":
                    urls["cv"] = full_url
                elif doc_type == "cover_letter":
                    urls["cover_letter"] = full_url
                elif doc_type == "diploma":
                    urls["diplome"] = full_url
                elif doc_type == "certificate":
                    urls["certificats"] = full_url
        
        return urls


# Instance globale
supabase_client = SupabaseClient()

