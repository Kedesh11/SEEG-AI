"""
Script de lancement de l'API FastAPI
"""
import uvicorn
from src.config import settings


if __name__ == "__main__":
    uvicorn.run(
        "src.api.app:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=True,
        log_level="info"
    )

