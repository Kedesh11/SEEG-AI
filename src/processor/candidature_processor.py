"""
Processeur principal pour le traitement des candidatures
"""
import json
import asyncio
from pathlib import Path
from typing import Dict, Any, List
from src.config import settings
from src.logger import app_logger as logger
from src.models import Candidature, Offre, ReponsesMTP, Documents, QuestionsMTP
from src.database.mongodb_client import mongodb_client
from src.services.supabase_client import supabase_client
from src.services.azure_ocr import azure_ocr_service


class CandidatureProcessor:
    """Processeur de candidatures avec OCR et stockage MongoDB"""
    
    def __init__(self):
        self.data_folder = Path(settings.data_folder)
        self.temp_folder = Path(settings.temp_folder)
        self.temp_folder.mkdir(parents=True, exist_ok=True)
    
    async def process_all_candidatures(self):
        """
        Traite toutes les candidatures du dossier data
        """
        logger.info("=" * 80)
        logger.info("DÉMARRAGE DU TRAITEMENT DES CANDIDATURES")
        logger.info("=" * 80)
        
        # Connexion aux services
        await self._connect_services()
        
        # Récupération du fichier JSON principal
        json_file = self.data_folder / "Donnees_candidatures_SEEG.json"
        
        if not json_file.exists():
            logger.warning(f"Fichier {json_file} non trouvé")
            return
        
        # Lecture du fichier JSON (c'est un tableau)
        with open(json_file, 'r', encoding='utf-8') as f:
            candidats_data = json.load(f)
        
        if not isinstance(candidats_data, list):
            logger.error("Le fichier JSON doit contenir un tableau de candidats")
            return
        
        logger.info(f"📁 {len(candidats_data)} candidatures trouvées dans le fichier")
        
        # Traitement de chaque candidature
        processed_count = 0
        failed_count = 0
        
        for idx, candidate_data in enumerate(candidats_data, 1):
            try:
                logger.info(f"\n{'=' * 80}")
                logger.info(f"Traitement candidat {idx}/{len(candidats_data)}")
                logger.info(f"{'=' * 80}")
                
                await self.process_single_candidature_from_data(candidate_data)
                processed_count += 1
                
            except Exception as e:
                logger.error(f"❌ Erreur traitement candidat {idx}: {e}")
                logger.exception(e)
                failed_count += 1
        
        # Résumé
        logger.info("\n" + "=" * 80)
        logger.info("RÉSUMÉ DU TRAITEMENT")
        logger.info("=" * 80)
        logger.info(f"✓ Candidatures traitées avec succès: {processed_count}")
        if failed_count > 0:
            logger.warning(f"❌ Candidatures en erreur: {failed_count}")
        logger.info("=" * 80)
    
    async def _connect_services(self):
        """Initialise les connexions aux services"""
        logger.info("Connexion aux services...")
        
        # MongoDB
        mongodb_client.connect()
        
        # Supabase
        supabase_client.connect()
        
        # Azure OCR
        azure_ocr_service.connect()
        
        logger.success("✓ Tous les services sont connectés")
    
    async def process_single_candidature_from_data(self, candidate_data: Dict[str, Any]):
        """
        Traite une candidature individuelle depuis les données JSON
        
        Args:
            candidate_data: Dictionnaire contenant les données du candidat
        """
        logger.info(f"📄 Traitement des données candidat")
        
        # Extraction de l'application_id unique
        application_id = candidate_data.get("application_id")
        
        # Extraction des informations de base
        candidature = self._build_candidature_from_json(candidate_data)
        
        logger.info(
            f"👤 Candidat: {candidature.first_name} {candidature.last_name} (ID: {application_id})"
        )
        
        # Récupération des URLs des documents
        document_urls = supabase_client.get_document_urls_from_candidate(
            candidate_data
        )
        
        if not document_urls:
            logger.warning("⚠️ Aucune URL de document trouvée")
        else:
            logger.info(f"📎 {len(document_urls)} documents à traiter")
        
        # Téléchargement et OCR des documents
        documents_text = await self._process_documents(
            document_urls,
            candidature.first_name,
            candidature.last_name
        )
        
        # Mise à jour de la candidature avec les textes extraits
        candidature.documents = Documents(**documents_text)
        
        # Sauvegarde dans MongoDB avec l'application_id comme clé unique
        candidat_id = mongodb_client.insert_or_update_candidature(
            candidature,
            application_id=application_id
        )
        
        logger.success(
            f"💾 Candidature sauvegardée (ID: {candidat_id})"
        )
    
    def _build_candidature_from_json(
        self,
        data: Dict[str, Any]
    ) -> Candidature:
        """
        Construit un objet Candidature depuis les données JSON réelles
        
        Args:
            data: Données JSON du candidat
            
        Returns:
            Objet Candidature
        """
        # Extraction des données de base
        first_name = data.get("first_name", "")
        last_name = data.get("last_name", "")
        
        # Construction de l'offre depuis les champs job_*
        offre = Offre(
            intitule=data.get("job_title"),
            reference=data.get("job_id"),
            ligne_hierarchique=None,  # Pas dans les données
            type_contrat=data.get("contract_type"),
            categorie=data.get("department"),
            salaire_brut=None,
            statut=data.get("status_offerts"),
            campagne_recrutement=None,
            active=True,
            date_embauche=None,
            lieu_travail=data.get("job_location"),
            date_limite_candidature=None,
            missions_principales=data.get("job_description"),
            connaissances_requises=None,
            questions_mtp=QuestionsMTP(
                metier=data.get("questions_metier_offre", []),
                talent=data.get("questions_talent_offre", []),
                paradigme=data.get("questions_paradigme_offre", [])
            ),
            date_publication=data.get("date_candidature"),
            autres_informations=None
        )
        
        # Extraction des réponses MTP
        reponses_data = data.get("reponses_mtp_candidat", {})
        reponses_mtp = ReponsesMTP(
            metier=reponses_data.get("metier", []),
            talent=reponses_data.get("talent", []),
            paradigme=reponses_data.get("paradigme", [])
        )
        
        # Création de la candidature
        candidature = Candidature(
            first_name=first_name,
            last_name=last_name,
            offre=offre,
            reponses_mtp=reponses_mtp,
            documents=Documents()
        )
        
        return candidature
    
    async def _process_documents(
        self,
        document_urls: Dict[str, str],
        first_name: str,
        last_name: str
    ) -> Dict[str, str]:
        """
        Télécharge et extrait le texte de tous les documents
        
        Args:
            document_urls: Dictionnaire des URLs des documents
            first_name: Prénom du candidat
            last_name: Nom du candidat
            
        Returns:
            Dictionnaire avec les textes extraits
        """
        documents_text = {
            "cv": None,
            "cover_letter": None,
            "diplome": None,
            "certificats": None
        }
        
        # Traitement de chaque document
        for doc_type, url in document_urls.items():
            if not url:
                continue
            
            try:
                logger.info(f"📄 Traitement {doc_type}...")
                
                # Création du chemin de destination
                safe_name = f"{first_name}_{last_name}".replace(" ", "_")
                file_extension = Path(url).suffix or ".pdf"
                destination = self.temp_folder / f"{safe_name}_{doc_type}{file_extension}"
                
                # Téléchargement du fichier
                success = await supabase_client.download_file(url, destination)
                
                if not success:
                    logger.warning(f"⚠️ Échec téléchargement {doc_type}")
                    continue
                
                # Extraction OCR
                extracted_text = azure_ocr_service.extract_text_from_file(
                    destination
                )
                
                if extracted_text:
                    documents_text[doc_type] = extracted_text
                    logger.success(
                        f"✓ {doc_type}: {len(extracted_text)} caractères extraits"
                    )
                else:
                    logger.warning(f"⚠️ Aucun texte extrait de {doc_type}")
                
                # Nettoyage du fichier temporaire (optionnel)
                # destination.unlink(missing_ok=True)
                
            except Exception as e:
                logger.error(f"❌ Erreur traitement {doc_type}: {e}")
                continue
        
        return documents_text


# Instance globale
candidature_processor = CandidatureProcessor()

