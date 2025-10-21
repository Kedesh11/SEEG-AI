"""
Tests pour le processeur de candidatures
"""
import pytest
import json
from pathlib import Path
from unittest.mock import patch, MagicMock, AsyncMock
from src.processor.candidature_processor import CandidatureProcessor
from src.models import Candidature


@pytest.fixture
def processor(temp_data_folder):
    """Fixture pour le processeur"""
    processor = CandidatureProcessor()
    processor.data_folder = temp_data_folder
    return processor


def test_build_candidature_from_json(processor, sample_candidature_data):
    """Test de construction d'une candidature depuis JSON"""
    candidature = processor._build_candidature_from_json(sample_candidature_data)
    
    assert isinstance(candidature, Candidature)
    assert candidature.first_name == "Jean"
    assert candidature.last_name == "Dupont"
    assert candidature.offre.intitule == "Développeur Python Senior"


def test_build_candidature_from_minimal_json(processor):
    """Test avec données JSON minimales"""
    minimal_data = {
        "first_name": "Alice",
        "last_name": "Test"
    }
    
    candidature = processor._build_candidature_from_json(minimal_data)
    
    assert candidature.first_name == "Alice"
    assert candidature.last_name == "Test"
    assert candidature.offre is not None


def test_build_candidature_with_alternative_keys(processor):
    """Test avec clés alternatives (prenom/nom)"""
    data = {
        "prenom": "Bob",
        "nom": "Martin"
    }
    
    candidature = processor._build_candidature_from_json(data)
    
    assert candidature.first_name == "Bob"
    assert candidature.last_name == "Martin"


@pytest.mark.asyncio
async def test_process_documents_empty(processor):
    """Test de traitement sans documents"""
    documents = await processor._process_documents(
        {},
        "Jean",
        "Dupont"
    )
    
    assert documents["cv"] is None
    assert documents["cover_letter"] is None
    assert documents["diplome"] is None
    assert documents["certificats"] is None


def test_no_json_files_in_data_folder(processor, temp_data_folder):
    """Test avec un dossier data vide"""
    # Le dossier est vide par défaut
    json_files = list(temp_data_folder.glob("*.json"))
    assert len(json_files) == 0

