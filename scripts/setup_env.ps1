# Script de configuration de l'environnement SEEG-AI (Windows PowerShell)

Write-Host "🚀 Configuration de l'environnement SEEG-AI" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Vérifier si Python est installé
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Python n'est pas installé" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Python détecté: $pythonVersion" -ForegroundColor Green

# Créer l'environnement virtuel
if (!(Test-Path "env")) {
    Write-Host "📦 Création de l'environnement virtuel..." -ForegroundColor Yellow
    python -m venv env
    Write-Host "✓ Environnement virtuel créé" -ForegroundColor Green
}
else {
    Write-Host "✓ Environnement virtuel déjà existant" -ForegroundColor Green
}

# Activer l'environnement virtuel
Write-Host "🔧 Activation de l'environnement virtuel..." -ForegroundColor Yellow
& ".\env\Scripts\Activate.ps1"

# Mettre à jour pip
Write-Host "📦 Mise à jour de pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# Installer les dépendances
Write-Host "📦 Installation des dépendances..." -ForegroundColor Yellow
pip install -r requirements.txt

# Créer les dossiers nécessaires
Write-Host "📁 Création des dossiers..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path data, temp, logs | Out-Null

# Vérifier si .env existe
if (!(Test-Path ".env")) {
    Write-Host "⚠️  Fichier .env non trouvé" -ForegroundColor Yellow
    Write-Host "📝 Veuillez créer un fichier .env avec vos configurations" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Exemple de contenu minimal :"
    Write-Host "AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://..."
    Write-Host "AZURE_DOCUMENT_INTELLIGENCE_KEY=..."
    Write-Host "SUPABASE_SERVICE_ROLE_KEY=..."
    Write-Host "MONGODB_CONNECTION_STRING=mongodb://localhost:27017"
}
else {
    Write-Host "✓ Fichier .env trouvé" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Configuration terminée !" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes :"
Write-Host "  1. Vérifiez votre fichier .env"
Write-Host "  2. Lancez MongoDB : docker-compose up -d mongodb"
Write-Host "  3. Testez l'API : python run_api.py"
Write-Host "  4. Traitez les candidatures : python main.py"
Write-Host ""

