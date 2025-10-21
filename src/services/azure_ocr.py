"""
Service d'extraction de texte via Azure Form Recognizer
"""
import time
from pathlib import Path
from typing import Optional
from azure.ai.formrecognizer import DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential
from tenacity import retry, stop_after_attempt, wait_exponential
from src.config import settings
from src.logger import app_logger as logger


class AzureOCRService:
    """Service d'OCR utilisant Azure Form Recognizer"""
    
    def __init__(self):
        self.client: Optional[DocumentAnalysisClient] = None
    
    def connect(self):
        """Initialise le client Azure Form Recognizer"""
        try:
            logger.info("Initialisation Azure Document Intelligence...")
            
            self.client = DocumentAnalysisClient(
                endpoint=settings.azure_document_intelligence_endpoint,
                credential=AzureKeyCredential(settings.azure_document_intelligence_key)
            )
            
            logger.success("✓ Client Azure Document Intelligence initialisé")
            
        except Exception as e:
            logger.error(f"Erreur initialisation Azure Document Intelligence: {e}")
            raise
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=10)
    )
    def extract_text_from_file(self, file_path: Path) -> str:
        """
        Extrait le texte d'un document PDF ou image
        
        Args:
            file_path: Chemin vers le fichier à analyser
            
        Returns:
            Texte extrait du document
        """
        try:
            logger.info(f"Extraction OCR: {file_path.name}")
            
            if not file_path.exists():
                logger.error(f"Fichier introuvable: {file_path}")
                return ""
            
            # Lecture du fichier
            with open(file_path, "rb") as f:
                document_bytes = f.read()
            
            # Lancement de l'analyse avec le modèle "prebuilt-read"
            # C'est le meilleur modèle pour l'extraction de texte générale  
            poller = self.client.begin_analyze_document(
                model_id="prebuilt-read",
                document=document_bytes
            )
            
            logger.debug(f"Analyse en cours pour {file_path.name}...")
            
            # Attente du résultat (peut prendre quelques secondes)
            result = poller.result()
            
            # Extraction du texte
            extracted_text = self._extract_text_from_result(result)
            
            logger.success(
                f"✓ OCR terminé: {file_path.name} "
                f"({len(extracted_text)} caractères extraits)"
            )
            
            return extracted_text
            
        except Exception as e:
            logger.error(f"Erreur extraction OCR {file_path.name}: {e}")
            return ""
    
    def _extract_text_from_result(self, result) -> str:
        """
        Extrait le texte structuré du résultat d'analyse
        
        Args:
            result: Résultat de l'analyse Azure
            
        Returns:
            Texte extrait et formaté
        """
        extracted_text = []
        
        # Extraction du contenu textuel
        if hasattr(result, 'content') and result.content:
            return result.content
        
        # Alternative: extraction page par page pour plus de contrôle
        if hasattr(result, 'pages') and result.pages:
            for page_idx, page in enumerate(result.pages, 1):
                if hasattr(page, 'lines') and page.lines:
                    page_text = []
                    for line in page.lines:
                        if hasattr(line, 'content'):
                            page_text.append(line.content)
                    
                    if page_text:
                        extracted_text.append(f"\n--- Page {page_idx} ---\n")
                        extracted_text.append("\n".join(page_text))
        
        return "\n".join(extracted_text).strip()
    
    async def extract_text_from_url(self, url: str) -> str:
        """
        Extrait le texte d'un document accessible via URL
        
        Args:
            url: URL du document à analyser
            
        Returns:
            Texte extrait du document
        """
        try:
            logger.info(f"Extraction OCR depuis URL: {url}")
            
            # Lancement de l'analyse depuis l'URL
            # Note: Cette méthode n'est plus utilisée, on télécharge d'abord les fichiers
            poller = self.client.begin_analyze_document_from_url(
                model_id="prebuilt-read",
                document_url=url
            )
            
            logger.debug("Analyse en cours depuis URL...")
            
            # Attente du résultat
            result = poller.result()
            
            # Extraction du texte
            extracted_text = self._extract_text_from_result(result)
            
            logger.success(
                f"✓ OCR terminé depuis URL "
                f"({len(extracted_text)} caractères extraits)"
            )
            
            return extracted_text
            
        except Exception as e:
            logger.error(f"Erreur extraction OCR depuis URL: {e}")
            return ""


# Instance globale
azure_ocr_service = AzureOCRService()

