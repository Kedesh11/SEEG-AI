"""
Configuration des tests pytest
"""
import pytest
import os
from pathlib import Path

# Configuration de l'environnement de test
os.environ["MONGODB_CONNECTION_STRING"] = "mongodb://localhost:27017"
os.environ["MONGODB_DATABASE"] = "seeg_candidatures_test"
os.environ["AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT"] = "https://test.cognitiveservices.azure.com/"
os.environ["AZURE_DOCUMENT_INTELLIGENCE_KEY"] = "test_key"
os.environ["SUPABASE_URL"] = "https://test.supabase.co"
os.environ["SUPABASE_SERVICE_ROLE_KEY"] = "test_key"


@pytest.fixture
def sample_candidature_data():
    """Fixture avec des données de candidature exemple"""
    return {
        "first_name": "Jean",
        "last_name": "Dupont",
        "offre": {
            "intitule": "Développeur Python Senior",
            "reference": "DEV-2025-001",
            "ligne_hierarchique": "Chef de Département IT",
            "type_contrat": "CDI",
            "categorie": "Technique",
            "salaire_brut": "Selon grille salariale SEEG",
            "statut": "Publiée",
            "campagne_recrutement": "Campagne 2025",
            "active": True,
            "date_embauche": "2025-11-01",
            "lieu_travail": "Libreville",
            "date_limite_candidature": "2025-10-31",
            "missions_principales": "Développement d'applications backend",
            "connaissances_requises": "Python, FastAPI, MongoDB, Azure",
            "questions_mtp": {
                "metier": ["Question M1", "Question M2", "Question M3"],
                "talent": ["Question T1", "Question T2", "Question T3"],
                "paradigme": ["Question P1", "Question P2", "Question P3"]
            },
            "date_publication": "2025-09-25",
            "autres_informations": "Poste basé à Libreville"
        },
        "reponses_mtp": {
            "metier": ["Réponse M1", "Réponse M2", "Réponse M3"],
            "talent": ["Réponse T1", "Réponse T2", "Réponse T3"],
            "paradigme": ["Réponse P1", "Réponse P2", "Réponse P3"]
        },
        "documents": {
            "cv": "Texte du CV extrait...",
            "cover_letter": "Texte de la lettre de motivation...",
            "diplome": "Texte du diplôme...",
            "certificats": "Texte des certificats..."
        }
    }


@pytest.fixture
def temp_data_folder(tmp_path):
    """Fixture créant un dossier temporaire pour les données"""
    data_folder = tmp_path / "data"
    data_folder.mkdir()
    return data_folder

