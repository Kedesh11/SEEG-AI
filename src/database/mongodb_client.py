"""
Client MongoDB pour la gestion des candidatures
"""
from typing import List, Optional, Dict, Any
from pymongo import MongoClient, ASCENDING
from pymongo.errors import DuplicateKeyError, PyMongoError
from src.config import settings
from src.logger import app_logger as logger
from src.models import Candidature


class MongoDBClient:
    """Client pour interagir avec MongoDB/Cosmos DB"""
    
    def __init__(self):
        self.client = None
        self.database = None
        self.collection = None
    
    def connect(self):
        """Établit la connexion à MongoDB"""
        try:
            # Construction de la chaîne de connexion
            connection_string = settings.mongodb_connection_string
            
            # Si username/password fournis (pour Cosmos DB), les injecter
            if settings.mongodb_username and settings.mongodb_password:
                connection_string = connection_string.replace(
                    "<user>", settings.mongodb_username
                ).replace(
                    "<password>", settings.mongodb_password
                )
            
            logger.info(f"Connexion à MongoDB: {settings.mongodb_database}")
            
            self.client = MongoClient(connection_string)
            self.database = self.client[settings.mongodb_database]
            self.collection = self.database[settings.mongodb_collection]
            
            # Création d'index pour optimiser les recherches
            self._create_indexes()
            
            # Test de connexion
            self.client.admin.command('ping')
            logger.success("✓ Connexion MongoDB établie avec succès")
            
        except Exception as e:
            logger.error(f"Erreur de connexion MongoDB: {e}")
            raise
    
    def _create_indexes(self):
        """Crée les index nécessaires"""
        try:
            # Index sur first_name et last_name pour les recherches
            self.collection.create_index([("first_name", ASCENDING)])
            self.collection.create_index([("last_name", ASCENDING)])
            
            # Index composé pour les recherches combinées
            self.collection.create_index([
                ("first_name", ASCENDING),
                ("last_name", ASCENDING)
            ])
            
            logger.debug("Index MongoDB créés")
        except Exception as e:
            logger.warning(f"Erreur création d'index: {e}")
    
    def insert_or_update_candidature(self, candidature: Candidature, application_id: str = None) -> str:
        """
        Insère ou met à jour une candidature (upsert pour idempotence)
        
        Args:
            candidature: Objet Candidature à insérer/mettre à jour
            application_id: ID unique de l'application (depuis JSON)
            
        Returns:
            ID de la candidature
        """
        try:
            # Conversion en dict
            candidature_dict = candidature.model_dump(
                exclude_none=False,
                by_alias=True
            )
            
            # Supprimer le champ _id s'il est None
            if "_id" in candidature_dict and candidature_dict["_id"] is None:
                del candidature_dict["_id"]
            
            # Utilisation de l'application_id comme clé unique si fourni
            if application_id:
                filter_query = {"application_id": application_id}
                candidature_dict["application_id"] = application_id
            else:
                # Fallback: utiliser first_name + last_name
                filter_query = {
                    "first_name": candidature.first_name,
                    "last_name": candidature.last_name
                }
            
            # Upsert
            result = self.collection.update_one(
                filter_query,
                {"$set": candidature_dict},
                upsert=True
            )
            
            if result.upserted_id:
                logger.info(
                    f"✓ Nouvelle candidature insérée: "
                    f"{candidature.first_name} {candidature.last_name}"
                )
                return str(result.upserted_id)
            else:
                logger.info(
                    f"✓ Candidature mise à jour: "
                    f"{candidature.first_name} {candidature.last_name}"
                )
                # Récupérer l'ID existant
                existing = self.collection.find_one(filter_query)
                return str(existing["_id"]) if existing else None
                
        except Exception as e:
            logger.error(f"Erreur insertion/mise à jour candidature: {e}")
            raise
    
    def get_all_candidatures(self) -> List[Dict[str, Any]]:
        """Récupère toutes les candidatures"""
        try:
            candidatures = list(self.collection.find({}))
            
            # Conversion des ObjectId en string
            for candidature in candidatures:
                candidature["_id"] = str(candidature["_id"])
            
            logger.info(f"✓ {len(candidatures)} candidatures récupérées")
            return candidatures
            
        except Exception as e:
            logger.error(f"Erreur récupération candidatures: {e}")
            raise
    
    def search_candidatures(
        self,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Recherche des candidatures par nom/prénom
        
        Args:
            first_name: Prénom à rechercher (optionnel)
            last_name: Nom à rechercher (optionnel)
            
        Returns:
            Liste des candidatures correspondantes
        """
        try:
            query = {}
            
            if first_name:
                # Recherche insensible à la casse
                query["first_name"] = {"$regex": first_name, "$options": "i"}
            
            if last_name:
                query["last_name"] = {"$regex": last_name, "$options": "i"}
            
            candidatures = list(self.collection.find(query))
            
            # Conversion des ObjectId en string
            for candidature in candidatures:
                candidature["_id"] = str(candidature["_id"])
            
            logger.info(
                f"✓ {len(candidatures)} candidatures trouvées "
                f"(first_name={first_name}, last_name={last_name})"
            )
            return candidatures
            
        except Exception as e:
            logger.error(f"Erreur recherche candidatures: {e}")
            raise
    
    def close(self):
        """Ferme la connexion MongoDB"""
        if self.client:
            self.client.close()
            logger.info("Connexion MongoDB fermée")


# Instance globale
mongodb_client = MongoDBClient()

