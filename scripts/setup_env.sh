#!/bin/bash

# Script de configuration de l'environnement SEEG-AI

echo "🚀 Configuration de l'environnement SEEG-AI"
echo "=========================================="

# Vérifier si Python est installé
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé"
    exit 1
fi

echo "✓ Python détecté: $(python3 --version)"

# Créer l'environnement virtuel
if [ ! -d "env" ]; then
    echo "📦 Création de l'environnement virtuel..."
    python3 -m venv env
    echo "✓ Environnement virtuel créé"
else
    echo "✓ Environnement virtuel déjà existant"
fi

# Activer l'environnement virtuel
echo "🔧 Activation de l'environnement virtuel..."
source env/bin/activate

# Mettre à jour pip
echo "📦 Mise à jour de pip..."
pip install --upgrade pip

# Installer les dépendances
echo "📦 Installation des dépendances..."
pip install -r requirements.txt

# Créer les dossiers nécessaires
echo "📁 Création des dossiers..."
mkdir -p data temp logs

# Vérifier si .env existe
if [ ! -f ".env" ]; then
    echo "⚠️  Fichier .env non trouvé"
    echo "📝 Veuillez créer un fichier .env avec vos configurations"
    echo ""
    echo "Exemple de contenu minimal :"
    echo "AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://..."
    echo "AZURE_DOCUMENT_INTELLIGENCE_KEY=..."
    echo "SUPABASE_SERVICE_ROLE_KEY=..."
    echo "MONGODB_CONNECTION_STRING=mongodb://localhost:27017"
else
    echo "✓ Fichier .env trouvé"
fi

echo ""
echo "=========================================="
echo "✅ Configuration terminée !"
echo ""
echo "Prochaines étapes :"
echo "  1. Vérifiez votre fichier .env"
echo "  2. Lancez MongoDB : docker-compose up -d mongodb"
echo "  3. Testez l'API : python run_api.py"
echo "  4. Traitez les candidatures : python main.py"
echo ""

