"""
Configuration du système de logging
"""
import sys
from loguru import logger
from src.config import settings


def setup_logger():
    """Configure le logger pour l'application"""
    logger.remove()  # Supprime le handler par défaut
    
    # Console output
    logger.add(
        sys.stdout,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan> - <level>{message}</level>",
        level=settings.log_level,
        colorize=True
    )
    
    # File output
    logger.add(
        "logs/seeg-ai_{time:YYYY-MM-DD}.log",
        rotation="00:00",
        retention="30 days",
        level="DEBUG",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function} - {message}"
    )
    
    return logger


# Logger global
app_logger = setup_logger()

