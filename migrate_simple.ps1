# Script de Migration Simplifié vers Azure Cosmos DB
# =====================================================

Write-Host "`n" -NoNewline
Write-Host "================================" -ForegroundColor Cyan
Write-Host "MIGRATION VERS AZURE COSMOS DB" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier la connexion Azure
Write-Host "Vérification connexion Azure..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json

if (-not $account) {
    Write-Host "Non connecté à Azure. Connexion..." -ForegroundColor Red
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "Connecté: $($account.user.name)" -ForegroundColor Green
Write-Host "Subscription: $($account.name)" -ForegroundColor Gray
Write-Host ""

# 2. Récupérer la connection string Cosmos DB
Write-Host "Récupération Connection String Cosmos DB..." -ForegroundColor Yellow

$cosmosKeys = az cosmosdb keys list `
    --name seeg-ai `
    --resource-group seeg-rg `
    --type connection-strings `
    --output json | ConvertFrom-Json

if (-not $cosmosKeys) {
    Write-Host "Impossible de récupérer la connection string" -ForegroundColor Red
    exit 1
}

$connectionString = $cosmosKeys.connectionStrings[0].connectionString
Write-Host "Connection String récupérée" -ForegroundColor Green
Write-Host ""

# 3. Vérifier le fichier source
$sourceFile = "data\Donnees_candidatures_SEEG.json"

if (-not (Test-Path $sourceFile)) {
    Write-Host "Fichier $sourceFile introuvable" -ForegroundColor Red
    exit 1
}

$candidatsData = Get-Content $sourceFile | ConvertFrom-Json
$totalCandidats = $candidatsData.Count

Write-Host "Candidats dans le fichier source: $totalCandidats" -ForegroundColor Cyan
Write-Host ""

# 4. Demander confirmation
Write-Host "================================" -ForegroundColor Cyan
Write-Host "MIGRATION DIRECTE AVEC OCR" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cette opération va:" -ForegroundColor Yellow
Write-Host "  - Télécharger les documents depuis Supabase" -ForegroundColor Gray
Write-Host "  - Extraire le texte avec Azure OCR (~0.01 euro/page)" -ForegroundColor Gray
Write-Host "  - Sauvegarder dans Cosmos DB Azure" -ForegroundColor Gray
Write-Host "  - Durée estimée: ~30 minutes pour $totalCandidats candidats" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Confirmer la migration ? (o/N)"

if ($confirm -ne 'o' -and $confirm -ne 'O') {
    Write-Host "Migration annulée" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "LANCEMENT DE LA MIGRATION" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 5. Vérifier que le script Python existe
if (-not (Test-Path "migrate_direct_to_cosmos.py")) {
    Write-Host "Script migrate_direct_to_cosmos.py introuvable" -ForegroundColor Red
    exit 1
}

# 6. Lancer la migration
python migrate_direct_to_cosmos.py "$connectionString"

$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan

if ($exitCode -eq 0) {
    Write-Host "MIGRATION TERMINÉE AVEC SUCCÈS" -ForegroundColor Green
}
else {
    Write-Host "MIGRATION TERMINÉE AVEC ERREURS" -ForegroundColor Yellow
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 7. Vérification de l'API
Write-Host "Test de l'API Azure..." -ForegroundColor Yellow

try {
    $health = Invoke-RestMethod -Uri "https://seeg-ai-api.azurewebsites.net/health" -TimeoutSec 10 -ErrorAction Stop
    
    if ($health.status -eq "healthy") {
        Write-Host "API Azure en ligne et connectée à Cosmos DB" -ForegroundColor Green
        
        $candidats = Invoke-RestMethod -Uri "https://seeg-ai-api.azurewebsites.net/candidatures" -TimeoutSec 30 -ErrorAction Stop
        $totalAPI = $candidats.Count
        
        Write-Host "Total candidats dans l'API: $totalAPI" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "API Azure non accessible (l'app démarre peut-être encore)" -ForegroundColor Yellow
    Write-Host "Testez dans quelques minutes: curl https://seeg-ai-api.azurewebsites.net/health" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Liens utiles:" -ForegroundColor White
Write-Host "  API:    https://seeg-ai-api.azurewebsites.net" -ForegroundColor Cyan
Write-Host "  Docs:   https://seeg-ai-api.azurewebsites.net/docs" -ForegroundColor Cyan
Write-Host "  Health: https://seeg-ai-api.azurewebsites.net/health" -ForegroundColor Cyan
Write-Host ""

