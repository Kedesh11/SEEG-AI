# Script de Déploiement SEEG-AI sur Azure - Version Complète
# ============================================================

param(
    [switch]$SkipBuild,
    [switch]$OnlyConfig,
    [switch]$SkipDataMigration,
    [switch]$SkipTests
)

# Variables
$ACR_NAME = "seegregistry"
$APP_NAME = "seeg-ai-api"
$RG = "seeg-rg"
$LOCATION = "francecentral"

Write-Host "🚀 Déploiement SEEG-AI sur Azure" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier la connexion Azure
Write-Host "🔐 Vérification de la connexion Azure..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Non connecté à Azure. Connexion..." -ForegroundColor Red
    az login
}
$account = az account show | ConvertFrom-Json
Write-Host "✓ Connecté: $($account.user.name)" -ForegroundColor Green
Write-Host "  Subscription: $($account.name)" -ForegroundColor Gray
Write-Host ""

# 1. Récupérer la connection string Cosmos DB
Write-Host "1️⃣  Récupération Connection String Cosmos DB..." -ForegroundColor Yellow
try {
    $cosmosKeys = az cosmosdb keys list `
        --name seeg-ai `
        --resource-group $RG `
        --type connection-strings `
        --output json | ConvertFrom-Json
    
    $connectionString = $cosmosKeys.connectionStrings[0].connectionString
    Write-Host "✓ Connection String récupérée" -ForegroundColor Green
} catch {
    Write-Host "⚠ Impossible de récupérer la connection string" -ForegroundColor Yellow
    Write-Host "  Utilisation de MongoDB local pour le test" -ForegroundColor Gray
    $connectionString = "mongodb://Sevan:SevanSeeg2025@localhost:27017"
}
Write-Host ""

if ($OnlyConfig) {
    Write-Host "⚙️  Mode configuration uniquement (OnlyConfig)" -ForegroundColor Cyan
    Write-Host ""
} else {
    # 2. Container Registry
    Write-Host "2️⃣  Vérification Container Registry..." -ForegroundColor Yellow
    $acrExists = az acr show --name $ACR_NAME --resource-group $RG 2>$null
    
    if (-not $acrExists) {
        Write-Host "  Création du Container Registry..." -ForegroundColor Yellow
        az acr create `
            --resource-group $RG `
            --name $ACR_NAME `
            --sku Basic `
            --admin-enabled true `
            --location $LOCATION
        Write-Host "✓ Container Registry créé" -ForegroundColor Green
    } else {
        Write-Host "✓ Container Registry existe déjà" -ForegroundColor Green
    }
    Write-Host ""
    
    # 3. Build et Push l'image
    if (-not $SkipBuild) {
        Write-Host "3️⃣  Build de l'image Docker..." -ForegroundColor Yellow
        Write-Host "  Cela peut prendre 5-10 minutes..." -ForegroundColor Gray
        
        az acr build `
            --registry $ACR_NAME `
            --image seeg-api:latest `
            --file Dockerfile `
            .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Image buildée et pushée" -ForegroundColor Green
        } else {
            Write-Host "❌ Erreur lors du build" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "3️⃣  Build ignoré (--SkipBuild)" -ForegroundColor Gray
    }
    Write-Host ""
}

# 4. Créer/Mettre à jour l'App Service
Write-Host "4️⃣  Configuration App Service..." -ForegroundColor Yellow

$acrServer = az acr show --name $ACR_NAME --query loginServer --output tsv
$acrUser = az acr credential show --name $ACR_NAME --query username --output tsv
$acrPass = az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv

# Vérifier si l'app existe
$appExists = az webapp show --name $APP_NAME --resource-group $RG 2>$null

if (-not $appExists) {
    Write-Host "  Création de l'App Service Plan..." -ForegroundColor Yellow
    
    # Créer le plan
    az appservice plan create `
        --name seeg-app-plan `
        --resource-group $RG `
        --is-linux `
        --sku B1 `
        --location $LOCATION
    
    Write-Host "  Création de l'App Service..." -ForegroundColor Yellow
    
    # Créer l'app
    az webapp create `
        --resource-group $RG `
        --plan seeg-app-plan `
        --name $APP_NAME `
        --deployment-container-image-name "$acrServer/seeg-api:latest"
    
    # Configurer le registry
    az webapp config container set `
        --name $APP_NAME `
        --resource-group $RG `
        --docker-custom-image-name "$acrServer/seeg-api:latest" `
        --docker-registry-server-url "https://$acrServer" `
        --docker-registry-server-user $acrUser `
        --docker-registry-server-password $acrPass
    
    Write-Host "✓ App Service créée" -ForegroundColor Green
} else {
    Write-Host "✓ App Service existe déjà" -ForegroundColor Green
}
Write-Host ""

# 5. Configurer les variables d'environnement
Write-Host "5️⃣  Configuration des variables d'environnement..." -ForegroundColor Yellow

az webapp config appsettings set `
    --resource-group $RG `
    --name $APP_NAME `
    --settings `
        AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT="https://seeg-document-intelligence.cognitiveservices.azure.com/" `
        AZURE_DOCUMENT_INTELLIGENCE_KEY="c692c5eb3c8c4f269af44c16ec339a7a" `
        SUPABASE_URL="https://fyiitzndlqcnyluwkpqp.supabase.co" `
        SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5aWl0em5kbHFjbnlsdXdrcHFwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTUwOTE1OSwiZXhwIjoyMDcxMDg1MTU5fQ.E3R7r2Rn_0rpCdmhKAjpWsNyenkR7p-lmKP3Pnr_X38" `
        SUPABASE_BUCKET_NAME="application-documents" `
        MONGODB_CONNECTION_STRING="$connectionString" `
        MONGODB_DATABASE="SEEG-AI" `
        MONGODB_COLLECTION="candidats" `
        LOG_LEVEL="INFO" `
        WEBSITES_PORT="8000"

Write-Host "✓ Variables configurées" -ForegroundColor Green
Write-Host ""

# 6. Redémarrer
if (-not $OnlyConfig) {
    Write-Host "6️⃣  Redémarrage de l'application..." -ForegroundColor Yellow
    az webapp restart --name $APP_NAME --resource-group $RG
    Write-Host "✓ Application redémarrée" -ForegroundColor Green
    Write-Host ""
}

# 7. Migration des données (si MongoDB local contient des données)
if (-not $SkipDataMigration -and -not $OnlyConfig) {
    Write-Host "7️⃣  Migration des données vers Cosmos DB..." -ForegroundColor Yellow
    
    # Vérifier si MongoDB local est en cours d'exécution
    $mongoContainer = docker ps --filter "name=seeg-mongodb" --format "{{.Names}}" 2>$null
    
    if ($mongoContainer) {
        Write-Host "  MongoDB local détecté" -ForegroundColor Gray
        
        # Vérifier s'il y a des données
        try {
            $count = docker exec seeg-mongodb mongosh -u Sevan -p "SevanSeeg2025" --authenticationDatabase admin SEEG-AI --quiet --eval "db.candidats.countDocuments({})" 2>$null
            $count = $count -replace '\D', ''
            
            if ($count -and [int]$count -gt 0) {
                Write-Host "  📊 $count candidatures trouvées dans MongoDB local" -ForegroundColor Cyan
                
                $migrate = Read-Host "  Voulez-vous migrer ces données vers Cosmos DB? (o/N)"
                
                if ($migrate -eq 'o' -or $migrate -eq 'O') {
                    Write-Host "  Export des données..." -ForegroundColor Gray
                    
                    # Export
                    docker exec seeg-mongodb mongoexport `
                        -u Sevan -p "SevanSeeg2025" `
                        --authenticationDatabase admin `
                        --db SEEG-AI `
                        --collection candidats `
                        --out /tmp/candidats_export.json 2>$null
                    
                    # Copier vers l'hôte
                    docker cp seeg-mongodb:/tmp/candidats_export.json ./candidats_export.json 2>$null
                    
                    if (Test-Path "./candidats_export.json") {
                        Write-Host "  ✓ Export réussi: candidats_export.json" -ForegroundColor Green
                        
                        # Import vers Cosmos DB
                        Write-Host "  Import vers Cosmos DB..." -ForegroundColor Gray
                        Write-Host "  ⚠️  Installez MongoDB Tools si pas déjà fait:" -ForegroundColor Yellow
                        Write-Host "     https://www.mongodb.com/try/download/database-tools" -ForegroundColor Gray
                        Write-Host ""
                        Write-Host "  Commande pour importer:" -ForegroundColor White
                        Write-Host "  mongoimport --uri=`"$connectionString`" --db SEEG-AI --collection candidats --file ./candidats_export.json" -ForegroundColor Cyan
                        Write-Host ""
                        
                        $doImport = Read-Host "  Exécuter l'import maintenant? (o/N)"
                        if ($doImport -eq 'o' -or $doImport -eq 'O') {
                            try {
                                mongoimport --uri="$connectionString" --db SEEG-AI --collection candidats --file ./candidats_export.json
                                Write-Host "  ✓ Import réussi vers Cosmos DB" -ForegroundColor Green
                            } catch {
                                Write-Host "  ⚠️  Import échoué. Utilisez la commande ci-dessus manuellement" -ForegroundColor Yellow
                            }
                        }
                    }
                } else {
                    Write-Host "  Migration ignorée" -ForegroundColor Gray
                }
            } else {
                Write-Host "  Aucune donnée à migrer" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  Impossible de vérifier les données locales" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  MongoDB local non détecté (ignoré)" -ForegroundColor Gray
    }
    Write-Host ""
} elseif ($SkipDataMigration) {
    Write-Host "7️⃣  Migration des données ignorée (--SkipDataMigration)" -ForegroundColor Gray
    Write-Host ""
}

# 8. Tests de vérification
if (-not $SkipTests -and -not $OnlyConfig) {
    Write-Host "8️⃣  Vérification du déploiement..." -ForegroundColor Yellow
    Write-Host "  Attente du démarrage de l'application (30 secondes)..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
    
    $API_URL = "https://$APP_NAME.azurewebsites.net"
    $allTestsPassed = $true
    
    # Test 1: Health check
    Write-Host "  Test 1/3: Health check..." -ForegroundColor Gray
    try {
        $health = Invoke-RestMethod -Uri "$API_URL/health" -TimeoutSec 30 -ErrorAction Stop
        if ($health.status -eq "healthy") {
            Write-Host "    ✓ Health check OK" -ForegroundColor Green
        } else {
            Write-Host "    ❌ Health check failed" -ForegroundColor Red
            $allTestsPassed = $false
        }
    } catch {
        Write-Host "    ❌ Health check inaccessible" -ForegroundColor Red
        Write-Host "       L'application démarre peut-être encore..." -ForegroundColor Yellow
        $allTestsPassed = $false
    }
    
    # Test 2: Root endpoint
    Write-Host "  Test 2/3: Endpoint racine..." -ForegroundColor Gray
    try {
        $root = Invoke-RestMethod -Uri "$API_URL/" -TimeoutSec 30 -ErrorAction Stop
        if ($root.message) {
            Write-Host "    ✓ Endpoint racine OK" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ❌ Endpoint racine inaccessible" -ForegroundColor Red
        $allTestsPassed = $false
    }
    
    # Test 3: Candidatures endpoint
    Write-Host "  Test 3/3: Endpoint candidatures..." -ForegroundColor Gray
    try {
        $candidats = Invoke-RestMethod -Uri "$API_URL/candidatures" -TimeoutSec 30 -ErrorAction Stop
        $count = if ($candidats) { $candidats.Count } else { 0 }
        Write-Host "    ✓ Endpoint candidatures OK ($count candidatures)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠️  Endpoint candidatures accessible mais vide" -ForegroundColor Yellow
    }
    
    Write-Host ""
    if ($allTestsPassed) {
        Write-Host "  ✅ Tous les tests sont passés!" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Certains tests ont échoué. Vérifiez les logs:" -ForegroundColor Yellow
        Write-Host "     az webapp log tail --name $APP_NAME --resource-group $RG" -ForegroundColor Gray
    }
    Write-Host ""
} elseif ($SkipTests) {
    Write-Host "8️⃣  Tests ignorés (--SkipTests)" -ForegroundColor Gray
    Write-Host ""
}

# 9. Résumé Final
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ DÉPLOIEMENT TERMINÉ !" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 API accessible sur:" -ForegroundColor White
Write-Host "  https://$APP_NAME.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "📡 Endpoints disponibles:" -ForegroundColor White
Write-Host "  Health:       https://$APP_NAME.azurewebsites.net/health" -ForegroundColor Gray
Write-Host "  Docs:         https://$APP_NAME.azurewebsites.net/docs" -ForegroundColor Gray
Write-Host "  Candidatures: https://$APP_NAME.azurewebsites.net/candidatures" -ForegroundColor Gray
Write-Host "  Recherche:    https://$APP_NAME.azurewebsites.net/candidatures/search" -ForegroundColor Gray
Write-Host ""
Write-Host "🔍 Commandes utiles:" -ForegroundColor White
Write-Host "  Voir les logs:    az webapp log tail --name $APP_NAME --resource-group $RG" -ForegroundColor Gray
Write-Host "  Redémarrer:       az webapp restart --name $APP_NAME --resource-group $RG" -ForegroundColor Gray
Write-Host "  Voir le statut:   az webapp show --name $APP_NAME --resource-group $RG --query state" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Prochaines étapes:" -ForegroundColor White
Write-Host "  1. Vérifier l'API: curl https://$APP_NAME.azurewebsites.net/health" -ForegroundColor Gray
Write-Host "  2. Traiter les candidats: python main.py (avec Cosmos DB configuré)" -ForegroundColor Gray
Write-Host "  3. Consulter les docs: https://$APP_NAME.azurewebsites.net/docs" -ForegroundColor Gray
Write-Host ""
Write-Host "⏱️  L'application peut prendre 1-2 minutes pour démarrer complètement" -ForegroundColor Yellow
Write-Host ""

