# Script de Migration Simplifiée vers Azure Cosmos DB
# ======================================================

param(
    [switch]$DirectMigration,  # Migration directe (avec OCR)
    [switch]$QuickMigration     # Migration rapide (depuis MongoDB local)
)

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "MIGRATION VERS AZURE COSMOS DB" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Vérifier la connexion Azure
Write-Host "Vérification connexion Azure..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Non connecté à Azure. Connexion..." -ForegroundColor Red
    az login
}
$account = az account show | ConvertFrom-Json
Write-Host "✓ Connecté: $($account.user.name)`n" -ForegroundColor Green

# Récupérer la connection string Cosmos DB
Write-Host "Récupération Connection String Cosmos DB..." -ForegroundColor Yellow
try {
    $cosmosKeys = az cosmosdb keys list `
        --name seeg-ai `
        --resource-group seeg-rg `
        --type connection-strings `
        --output json | ConvertFrom-Json
    
    $connectionString = $cosmosKeys.connectionStrings[0].connectionString
    Write-Host "✓ Connection String récupérée`n" -ForegroundColor Green
}
catch {
    Write-Host "✗ Impossible de récupérer la connection string" -ForegroundColor Red
    exit 1
}

# Vérifier le fichier source
$sourceFile = "data\Donnees_candidatures_SEEG.json"
if (-not (Test-Path $sourceFile)) {
    Write-Host "✗ Fichier $sourceFile introuvable" -ForegroundColor Red
    exit 1
}

# Compter les candidats
$candidatsData = Get-Content $sourceFile | ConvertFrom-Json
$totalCandidats = $candidatsData.Count
Write-Host "📁 Candidats dans le fichier source: $totalCandidats" -ForegroundColor Cyan
Write-Host ""

# Si aucun flag, demander à l'utilisateur
if (-not $DirectMigration -and -not $QuickMigration) {
    Write-Host "Quelle méthode de migration souhaitez-vous utiliser ?`n" -ForegroundColor Yellow
    Write-Host "1. Migration Directe (RECOMMANDÉE)" -ForegroundColor White
    Write-Host "   - Lit depuis data/Donnees_candidatures_SEEG.json"
    Write-Host "   - Traitement OCR complet"
    Write-Host "   - Durée: ~30 minutes pour $totalCandidats candidats"
    Write-Host "   - Coût OCR: ~2-3€`n"
    
    Write-Host "2. Migration Rapide (depuis MongoDB local)" -ForegroundColor White
    Write-Host "   - Nécessite que les candidats soient déjà traités localement"
    Write-Host "   - Export → Import (pas d'OCR)"
    Write-Host "   - Durée: ~2-3 minutes`n"
    
    $choix = Read-Host "Votre choix (1 ou 2)"
    
    if ($choix -eq "1") {
        $DirectMigration = $true
    }
    elseif ($choix -eq "2") {
        $QuickMigration = $true
    }
    else {
        Write-Host "✗ Choix invalide" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan

# MÉTHODE 1 : Migration Directe
if ($DirectMigration) {
    Write-Host "MIGRATION DIRECTE AVEC TRAITEMENT OCR" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "⚠️  Cette opération va:" -ForegroundColor Yellow
    Write-Host "   - Télécharger les documents depuis Supabase"
    Write-Host "   - Extraire le texte avec Azure OCR (~0.01€/page)"
    Write-Host "   - Sauvegarder dans Cosmos DB Azure"
    Write-Host "   - Durée estimée: ~30 minutes pour $totalCandidats candidats`n"
    
    $confirm = Read-Host "Confirmer la migration directe ? (o/N)"
    
    if ($confirm -ne 'o' -and $confirm -ne 'O') {
        Write-Host "Migration annulée`n" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    Write-Host "🚀 Lancement de la migration directe..." -ForegroundColor Green
    Write-Host ""
    
    # Vérifier que le script existe
    if (-not (Test-Path "migrate_direct_to_cosmos.py")) {
        Write-Host "✗ Script migrate_direct_to_cosmos.py introuvable" -ForegroundColor Red
        exit 1
    }
    
    # Lancer la migration
    python migrate_direct_to_cosmos.py "$connectionString"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Migration directe terminée avec succès !`n" -ForegroundColor Green
    }
    else {
        Write-Host "`n⚠️  Migration terminée avec des erreurs" -ForegroundColor Yellow
        Write-Host "Vous pouvez relancer le script pour continuer`n" -ForegroundColor Gray
    }
}

# MÉTHODE 2 : Migration Rapide
elseif ($QuickMigration) {
    Write-Host "MIGRATION RAPIDE DEPUIS MONGODB LOCAL" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
    
    # Vérifier MongoDB local
    Write-Host "Vérification MongoDB local..." -ForegroundColor Yellow
    $mongoContainer = docker ps --filter "name=seeg-mongodb" --format "{{.Names}}" 2>$null
    
    if (-not $mongoContainer) {
        Write-Host "✗ MongoDB local non démarré" -ForegroundColor Red
        Write-Host "Lancer: docker-compose up -d mongodb`n" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "✓ MongoDB local actif`n" -ForegroundColor Green
    
    # Compter les documents locaux
    try {
        $count = docker exec seeg-mongodb mongosh -u Sevan -p "SevanSeeg2025" --authenticationDatabase admin SEEG-AI --quiet --eval "db.candidats.countDocuments({})" 2>$null
        $count = $count -replace '\D', ''
        
        if ([int]$count -eq 0) {
            Write-Host "⚠️  Aucun candidat dans MongoDB local" -ForegroundColor Yellow
            Write-Host "Exécutez d'abord: python main.py`n" -ForegroundColor Gray
            exit 1
        }
        
        Write-Host "📊 Candidats dans MongoDB local: $count" -ForegroundColor Cyan
        Write-Host ""
        
        $confirm = Read-Host "Exporter et migrer ces $count candidats vers Cosmos DB ? (o/N)"
        
        if ($confirm -ne 'o' -and $confirm -ne 'O') {
            Write-Host "Migration annulée`n" -ForegroundColor Yellow
            exit 0
        }
        
        # Export
        Write-Host "`n📦 Export depuis MongoDB local..." -ForegroundColor Yellow
        docker exec seeg-mongodb mongoexport `
            -u Sevan -p "SevanSeeg2025" `
            --authenticationDatabase admin `
            --db SEEG-AI `
            --collection candidats `
            --out /tmp/candidats_export.json 2>$null | Out-Null
        
        docker cp seeg-mongodb:/tmp/candidats_export.json ./candidats_export.json 2>$null
        
        if (-not (Test-Path "candidats_export.json")) {
            Write-Host "✗ Échec de l'export" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✓ Export réussi: candidats_export.json`n" -ForegroundColor Green
        
        # Migration
        Write-Host "🚀 Migration vers Cosmos DB..." -ForegroundColor Yellow
        Write-Host ""
        
        python migrate_to_cosmos.py "$connectionString"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Migration rapide terminée avec succès !`n" -ForegroundColor Green
            
            # Nettoyage
            $clean = Read-Host "Supprimer candidats_export.json ? (o/N)"
            if ($clean -eq 'o' -or $clean -eq 'O') {
                Remove-Item candidats_export.json -Force
                Write-Host "✓ Fichier nettoyé`n" -ForegroundColor Green
            }
        }
        else {
            Write-Host "`n⚠️  Migration terminée avec des erreurs" -ForegroundColor Yellow
            Write-Host "Vous pouvez relancer: python migrate_to_cosmos.py `"$connectionString`"`n" -ForegroundColor Gray
        }
        
    }
    catch {
        Write-Host "✗ Erreur lors de l'export/migration: $_" -ForegroundColor Red
        exit 1
    }
}

# Vérification finale
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "VÉRIFICATION" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 Test de l'API Azure..." -ForegroundColor Yellow

try {
    $health = Invoke-RestMethod -Uri "https://seeg-ai-api.azurewebsites.net/health" -TimeoutSec 10
    
    if ($health.status -eq "healthy") {
        Write-Host "✓ API Azure en ligne et connectée à Cosmos DB`n" -ForegroundColor Green
        
        try {
            $candidats = Invoke-RestMethod -Uri "https://seeg-ai-api.azurewebsites.net/candidatures" -TimeoutSec 30
            $totalAPI = $candidats.Count
            
            Write-Host "📊 Total candidats dans l'API: $totalAPI`n" -ForegroundColor Cyan
            
            if ($totalAPI -gt 0) {
                Write-Host "📋 Derniers candidats:" -ForegroundColor White
                $candidats | Select-Object -Last 5 | ForEach-Object {
                    $nom = "$($_.first_name) $($_.last_name)"
                    $poste = $_.offre.intitule
                    Write-Host "   - $nom → $poste" -ForegroundColor Gray
                }
            }
        }
        catch {
            Write-Host "⚠️  API accessible mais impossible de récupérer les candidatures" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "⚠️  API Azure non accessible (l'app démarre peut-être encore)" -ForegroundColor Yellow
    Write-Host "Attendez 1-2 minutes et testez: curl https://seeg-ai-api.azurewebsites.net/health" -ForegroundColor Gray
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "✅ MIGRATION TERMINÉE" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

Write-Host "🌐 Liens utiles:" -ForegroundColor White
Write-Host "   API:      https://seeg-ai-api.azurewebsites.net" -ForegroundColor Cyan
Write-Host "   Docs:     https://seeg-ai-api.azurewebsites.net/docs" -ForegroundColor Cyan
Write-Host "   Health:   https://seeg-ai-api.azurewebsites.net/health" -ForegroundColor Cyan
Write-Host "   Portal:   https://portal.azure.com (Cosmos DB → seeg-ai)" -ForegroundColor Cyan
Write-Host ""

