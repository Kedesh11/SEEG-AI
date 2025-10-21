"""
Tests unitaires pour les modèles Pydantic
"""
import pytest
from src.models import Candidature, Offre, Documents, ReponsesMTP, QuestionsMTP


def test_candidature_creation(sample_candidature_data):
    """Test de création d'une candidature valide"""
    candidature = Candidature(**sample_candidature_data)
    
    assert candidature.first_name == "Jean"
    assert candidature.last_name == "Dupont"
    assert candidature.offre.intitule == "Développeur Python Senior"
    assert candidature.documents.cv == "Texte du CV extrait..."


def test_candidature_with_minimal_data():
    """Test de création avec données minimales"""
    candidature = Candidature(
        first_name="Alice",
        last_name="Martin"
    )
    
    assert candidature.first_name == "Alice"
    assert candidature.last_name == "Martin"
    assert candidature.offre is not None
    assert candidature.documents is not None


def test_offre_default_values():
    """Test des valeurs par défaut de l'offre"""
    offre = Offre()
    
    assert offre.active is True
    assert offre.questions_mtp is not None
    assert isinstance(offre.questions_mtp, QuestionsMTP)


def test_documents_optional_fields():
    """Test que les champs documents sont optionnels"""
    docs = Documents()
    
    assert docs.cv is None
    assert docs.cover_letter is None
    assert docs.diplome is None
    assert docs.certificats is None


def test_candidature_serialization(sample_candidature_data):
    """Test de sérialisation/désérialisation"""
    candidature = Candidature(**sample_candidature_data)
    
    # Conversion en dict
    candidature_dict = candidature.model_dump()
    
    assert "first_name" in candidature_dict
    assert "last_name" in candidature_dict
    assert "offre" in candidature_dict
    assert "documents" in candidature_dict
    
    # Recréation depuis le dict
    candidature2 = Candidature(**candidature_dict)
    
    assert candidature2.first_name == candidature.first_name
    assert candidature2.last_name == candidature.last_name

