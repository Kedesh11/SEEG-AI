"""
Tests d'intégration pour l'API FastAPI
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from src.api.app import app


@pytest.fixture
def client():
    """Fixture pour le client de test FastAPI"""
    return TestClient(app)


@pytest.fixture
def mock_mongodb():
    """Mock du client MongoDB"""
    with patch("src.api.app.mongodb_client") as mock:
        yield mock


def test_root_endpoint(client):
    """Test du endpoint racine"""
    response = client.get("/")
    
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "endpoints" in data


def test_get_all_candidatures_success(client, mock_mongodb, sample_candidature_data):
    """Test de récupération de toutes les candidatures"""
    # Configuration du mock
    mock_mongodb.get_all_candidatures.return_value = [sample_candidature_data]
    
    response = client.get("/candidatures")
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == 1
    assert data[0]["first_name"] == "Jean"


def test_get_all_candidatures_empty(client, mock_mongodb):
    """Test avec aucune candidature"""
    mock_mongodb.get_all_candidatures.return_value = []
    
    response = client.get("/candidatures")
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == 0


def test_search_candidatures_by_first_name(client, mock_mongodb, sample_candidature_data):
    """Test de recherche par prénom"""
    mock_mongodb.search_candidatures.return_value = [sample_candidature_data]
    
    response = client.get("/candidatures/search?first_name=Jean")
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["first_name"] == "Jean"
    
    # Vérifier que la méthode a été appelée avec les bons paramètres
    mock_mongodb.search_candidatures.assert_called_once_with(
        first_name="Jean",
        last_name=None
    )


def test_search_candidatures_by_last_name(client, mock_mongodb, sample_candidature_data):
    """Test de recherche par nom"""
    mock_mongodb.search_candidatures.return_value = [sample_candidature_data]
    
    response = client.get("/candidatures/search?last_name=Dupont")
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1


def test_search_candidatures_by_both(client, mock_mongodb, sample_candidature_data):
    """Test de recherche par prénom et nom"""
    mock_mongodb.search_candidatures.return_value = [sample_candidature_data]
    
    response = client.get("/candidatures/search?first_name=Jean&last_name=Dupont")
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1


def test_search_candidatures_no_params(client, mock_mongodb):
    """Test de recherche sans paramètres (doit échouer)"""
    response = client.get("/candidatures/search")
    
    assert response.status_code == 400
    data = response.json()
    assert "detail" in data


def test_search_candidatures_not_found(client, mock_mongodb):
    """Test de recherche sans résultat"""
    mock_mongodb.search_candidatures.return_value = []
    
    response = client.get("/candidatures/search?first_name=Inconnu")
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 0

