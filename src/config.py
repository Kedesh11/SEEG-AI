"""
Configuration centralisée de l'application
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Configuration de l'application depuis les variables d'environnement"""
    
    # Azure Document Intelligence
    azure_document_intelligence_endpoint: str
    azure_document_intelligence_key: str
    
    # Supabase
    supabase_url: str = "https://fyiitzndlqcnyluwkpqp.supabase.co"
    supabase_service_role_key: str = ""  # Optionnel si accès public au bucket
    supabase_bucket_name: str = "application-documents"  # Nom du bucket réel
    
    # MongoDB / Cosmos DB
    mongodb_connection_string: str = "mongodb://Sevan:SevanSeeg2025@localhost:27017"
    cosmos_connection_string: Optional[str] = None  # Alias pour COSMOS_CONNECTION_STRING
    mongodb_database: str = "SEEG-AI"
    mongodb_collection: str = "candidats"
    mongodb_username: Optional[str] = None
    mongodb_password: Optional[str] = None
    
    # Application Settings
    log_level: str = "INFO"
    data_folder: str = "./data"
    temp_folder: str = "./temp"
    
    # API Settings
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    
    class Config:
        env_file = ".env"
        case_sensitive = False


# Instance globale des settings
settings = Settings()

