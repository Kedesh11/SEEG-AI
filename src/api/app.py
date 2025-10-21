"""
API FastAPI pour consulter les candidatures
"""
from typing import List, Optional
from fastapi import FastAPI, Query, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from src.logger import app_logger as logger
from src.database.mongodb_client import mongodb_client
from src.models import Candidature


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application"""
    # Démarrage
    logger.info("🚀 Démarrage de l'API SEEG-AI")
    mongodb_client.connect()
    logger.success("✓ API prête")
    
    yield
    
    # Arrêt
    logger.info("⏹️  Arrêt de l'API")
    mongodb_client.close()


# Création de l'application FastAPI
app = FastAPI(
    title="SEEG-AI API",
    description="API de consultation des candidatures traitées par OCR",
    version="1.0.0",
    lifespan=lifespan
)

# Configuration CORS (accès public)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permet toutes les origines (API publique)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Point d'entrée racine de l'API"""
    return {
        "message": "Bienvenue sur l'API SEEG-AI",
        "version": "1.0.0",
        "endpoints": {
            "candidatures": "/candidatures",
            "search": "/candidatures/search?first_name=XXX&last_name=YYY",
            "health": "/health"
        }
    }


@app.get("/health")
async def health_check():
    """Vérification de l'état de santé de l'API"""
    try:
        # Test de connexion MongoDB
        mongodb_client.collection.find_one()
        
        return {
            "status": "healthy",
            "database": "connected"
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(
            status_code=503,
            detail="Service unavailable"
        )


@app.get("/candidatures", response_model=List[Candidature])
async def get_all_candidatures():
    """
    Récupère toutes les candidatures
    
    Returns:
        Liste de toutes les candidatures stockées dans MongoDB
    """
    try:
        logger.info("📋 Récupération de toutes les candidatures")
        
        candidatures = mongodb_client.get_all_candidatures()
        
        logger.success(f"✓ {len(candidatures)} candidatures retournées")
        
        return candidatures
        
    except Exception as e:
        logger.error(f"Erreur récupération candidatures: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des candidatures: {str(e)}"
        )


@app.get("/candidatures/search", response_model=List[Candidature])
async def search_candidatures(
    first_name: Optional[str] = Query(
        None,
        description="Prénom du candidat à rechercher (insensible à la casse)"
    ),
    last_name: Optional[str] = Query(
        None,
        description="Nom du candidat à rechercher (insensible à la casse)"
    )
):
    """
    Recherche des candidatures par nom et/ou prénom
    
    Args:
        first_name: Prénom à rechercher (optionnel)
        last_name: Nom à rechercher (optionnel)
    
    Returns:
        Liste des candidatures correspondant aux critères de recherche
    
    Examples:
        - /candidatures/search?first_name=Sevan
        - /candidatures/search?last_name=Kedesh
        - /candidatures/search?first_name=Sevan&last_name=Kedesh
    """
    try:
        # Validation : au moins un paramètre requis
        if not first_name and not last_name:
            raise HTTPException(
                status_code=400,
                detail="Au moins un paramètre (first_name ou last_name) est requis"
            )
        
        logger.info(
            f"🔍 Recherche candidatures: "
            f"first_name={first_name}, last_name={last_name}"
        )
        
        candidatures = mongodb_client.search_candidatures(
            first_name=first_name,
            last_name=last_name
        )
        
        logger.success(f"✓ {len(candidatures)} candidatures trouvées")
        
        return candidatures
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur recherche candidatures: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la recherche: {str(e)}"
        )


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Gestionnaire d'erreurs global"""
    logger.error(f"Erreur non gérée: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Une erreur interne s'est produite",
            "detail": str(exc)
        }
    )

