# Makefile pour SEEG-AI

.PHONY: help install test run-api run-processor docker-build docker-up docker-down clean lint format

help:
	@echo "📋 Commandes disponibles pour SEEG-AI:"
	@echo ""
	@echo "  make install       - Installer les dépendances"
	@echo "  make test          - Exécuter les tests"
	@echo "  make test-cov      - Tests avec couverture"
	@echo "  make run-api       - Lancer l'API"
	@echo "  make run-processor - Lancer le traitement des candidatures"
	@echo "  make lint          - Vérifier le code (flake8)"
	@echo "  make format        - Formater le code (black)"
	@echo "  make docker-build  - Build l'image Docker"
	@echo "  make docker-up     - Démarrer les services Docker"
	@echo "  make docker-down   - Arrêter les services Docker"
	@echo "  make clean         - Nettoyer les fichiers temporaires"
	@echo ""

install:
	@echo "📦 Installation des dépendances..."
	pip install -r requirements.txt
	@echo "✅ Installation terminée"

test:
	@echo "🧪 Exécution des tests..."
	pytest -v

test-cov:
	@echo "🧪 Exécution des tests avec couverture..."
	pytest --cov=src --cov-report=html --cov-report=term
	@echo "📊 Rapport disponible dans htmlcov/index.html"

run-api:
	@echo "🚀 Lancement de l'API..."
	python run_api.py

run-processor:
	@echo "⚙️  Lancement du traitement des candidatures..."
	python main.py

lint:
	@echo "🔍 Vérification du code..."
	flake8 src/ --max-line-length=100 --exclude=__pycache__,*.pyc

format:
	@echo "✨ Formatage du code..."
	black src/ tests/

docker-build:
	@echo "🐳 Build de l'image Docker..."
	docker build -t seeg-ai:latest .

docker-up:
	@echo "🐳 Démarrage des services Docker..."
	docker-compose up -d
	@echo "✅ Services démarrés"
	@echo "   - API: http://localhost:8000"
	@echo "   - MongoDB: localhost:27017"
	@echo "   - Mongo Express: http://localhost:8081"

docker-down:
	@echo "🐳 Arrêt des services Docker..."
	docker-compose down

docker-logs:
	@echo "📋 Logs des services Docker..."
	docker-compose logs -f

clean:
	@echo "🧹 Nettoyage..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -rf htmlcov/ .coverage 2>/dev/null || true
	rm -rf temp/* 2>/dev/null || true
	@echo "✅ Nettoyage terminé"

setup-dev:
	@echo "🔧 Configuration de l'environnement de développement..."
	python -m venv env
	@echo "✅ Environnement virtuel créé"
	@echo "⚠️  Activez l'environnement avec: source env/bin/activate"
	@echo "⚠️  Puis lancez: make install"

init-folders:
	@echo "📁 Création des dossiers..."
	mkdir -p data temp logs
	@echo "✅ Dossiers créés"

