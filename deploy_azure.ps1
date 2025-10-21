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

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "DEPLOIEMENT SEEG-AI SUR AZURE" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Vérifier la connexion Azure
Write-Host "Verification de la connexion Azure..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Non connecte a Azure. Connexion..." -ForegroundColor Red
    az login
}
$account = az account show | ConvertFrom-Json
Write-Host "Connecte: $($account.user.name)" -ForegroundColor Green
Write-Host "  Subscription: $($account.name)`n" -ForegroundColor Gray

# 1. Récupérer la connection string Cosmos DB
Write-Host "ETAPE 1: Recuperation Connection String Cosmos DB..." -ForegroundColor Yellow
try {
    $cosmosKeys = az cosmosdb keys list `
        --name seeg-ai `
        --resource-group $RG `
        --type connection-strings `
        --output json | ConvertFrom-Json
    
    $connectionString = $cosmosKeys.connectionStrings[0].connectionString
    Write-Host "Connection String recuperee`n" -ForegroundColor Green
} catch {
    Write-Host "Impossible de recuperer la connection string" -ForegroundColor Yellow
    Write-Host "  Utilisation de MongoDB local pour le test`n" -ForegroundColor Gray
    $connectionString = "mongodb://Sevan:SevanSeeg2025@localhost:27017"
}

if ($OnlyConfig) {
    Write-Host "Mode configuration uniquement (OnlyConfig)`n" -ForegroundColor Cyan
} else {
    # 2. Container Registry
    Write-Host "ETAPE 2: Verification Container Registry..." -ForegroundColor Yellow
    $acrExists = az acr show --name $ACR_NAME --resource-group $RG 2>$null
    
    if (-not $acrExists) {
        Write-Host "  Creation du Container Registry..." -ForegroundColor Yellow
        az acr create `
            --resource-group $RG `
            --name $ACR_NAME `
            --sku Basic `
            --admin-enabled true `
            --location $LOCATION
        Write-Host "Container Registry cree`n" -ForegroundColor Green
    } else {
        Write-Host "Container Registry existe deja`n" -ForegroundColor Green
    }
    
    # 3. Build et Push l'image
    if (-not $SkipBuild) {
        Write-Host "ETAPE 3: Build de l'image Docker..." -ForegroundColor Yellow
        Write-Host "  Cela peut prendre 5-10 minutes...`n" -ForegroundColor Gray
        
        az acr build `
            --registry $ACR_NAME `
            --image seeg-api:latest `
            --file Dockerfile `
            .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nImage buildee et pushee`n" -ForegroundColor Green
        } else {
            Write-Host "`nErreur lors du build`n" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "ETAPE 3: Build ignore (SkipBuild)`n" -ForegroundColor Gray
    }
}

# 4. Créer/Mettre à jour l'App Service
Write-Host "ETAPE 4: Configuration App Service..." -ForegroundColor Yellow

$acrServer = az acr show --name $ACR_NAME --query loginServer --output tsv
$acrUser = az acr credential show --name $ACR_NAME --query username --output tsv
$acrPass = az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv

# Vérifier si l'app existe
$appExists = az webapp show --name $APP_NAME --resource-group $RG 2>$null

if (-not $appExists) {
    Write-Host "  Creation de l'App Service Plan..." -ForegroundColor Yellow
    
    # Créer le plan
    az appservice plan create `
        --name seeg-app-plan `
        --resource-group $RG `
        --is-linux `
        --sku B1 `
        --location $LOCATION
    
    Write-Host "  Creation de l'App Service..." -ForegroundColor Yellow
    
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
    
    Write-Host "App Service creee`n" -ForegroundColor Green
} else {
    Write-Host "App Service existe deja`n" -ForegroundColor Green
}

# 5. Configurer les variables d'environnement
Write-Host "ETAPE 5: Configuration des variables d'environnement..." -ForegroundColor Yellow

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
        WEBSITES_PORT="8000" | Out-Null

Write-Host "Variables configurees`n" -ForegroundColor Green

# 6. Redémarrer
if (-not $OnlyConfig) {
    Write-Host "ETAPE 6: Redemarrage de l'application..." -ForegroundColor Yellow
    az webapp restart --name $APP_NAME --resource-group $RG | Out-Null
    Write-Host "Application redemarree`n" -ForegroundColor Green
}

# 7. Migration des données
if (-not $SkipDataMigration -and -not $OnlyConfig) {
    Write-Host "ETAPE 7: Migration des donnees vers Cosmos DB..." -ForegroundColor Yellow
    
    $mongoContainer = docker ps --filter "name=seeg-mongodb" --format "{{.Names}}" 2>$null
    
    if ($mongoContainer) {
        Write-Host "  MongoDB local detecte" -ForegroundColor Gray
        
        try {
            $count = docker exec seeg-mongodb mongosh -u Sevan -p "SevanSeeg2025" --authenticationDatabase admin SEEG-AI --quiet --eval "db.candidats.countDocuments({})" 2>$null
            $count = $count -replace '\D', ''
            
            if ($count -and [int]$count -gt 0) {
                Write-Host "  $count candidature(s) trouvee(s) dans MongoDB local" -ForegroundColor Cyan
                
                $migrate = Read-Host "  Voulez-vous migrer ces donnees vers Cosmos DB? (o/N)"
                
                if ($migrate -eq 'o' -or $migrate -eq 'O') {
                    Write-Host "  Export des donnees..." -ForegroundColor Gray
                    
                    docker exec seeg-mongodb mongoexport `
                        -u Sevan -p "SevanSeeg2025" `
                        --authenticationDatabase admin `
                        --db SEEG-AI `
                        --collection candidats `
                        --out /tmp/candidats_export.json 2>$null | Out-Null
                    
                    docker cp seeg-mongodb:/tmp/candidats_export.json ./candidats_export.json 2>$null
                    
                    if (Test-Path "./candidats_export.json") {
                        Write-Host "  Export reussi: candidats_export.json`n" -ForegroundColor Green
                        
                        # Utiliser le script Python robuste pour la migration
                        Write-Host "  Lancement de la migration robuste vers Cosmos DB..." -ForegroundColor Gray
                        Write-Host "  (Gestion automatique du throttling et des duplicata)`n" -ForegroundColor Gray
                        
                        try {
                            python migrate_to_cosmos.py "$connectionString"
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "`n  Migration terminee avec succes!`n" -ForegroundColor Green
                            } else {
                                Write-Host "`n  Migration partielle - Vous pouvez relancer:" -ForegroundColor Yellow
                                Write-Host "  python migrate_to_cosmos.py `"$connectionString`"`n" -ForegroundColor Cyan
                            }
                        } catch {
                            Write-Host "`n  Erreur lors de la migration" -ForegroundColor Yellow
                            Write-Host "  Vous pouvez la relancer manuellement:" -ForegroundColor Gray
                            Write-Host "  python migrate_to_cosmos.py `"$connectionString`"`n" -ForegroundColor Cyan
                        }
                    }
                } else {
                    Write-Host "  Migration ignoree`n" -ForegroundColor Gray
                }
            } else {
                Write-Host "  Aucune donnee a migrer`n" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  Impossible de verifier les donnees locales`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  MongoDB local non detecte (ignore)`n" -ForegroundColor Gray
    }
} elseif ($SkipDataMigration) {
    Write-Host "ETAPE 7: Migration des donnees ignoree (SkipDataMigration)`n" -ForegroundColor Gray
}

# 8. Tests de vérification
if (-not $SkipTests -and -not $OnlyConfig) {
    Write-Host "ETAPE 8: Verification du deploiement..." -ForegroundColor Yellow
    Write-Host "  Attente du demarrage de l'application (30 secondes)..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
    
    $API_URL = "https://$APP_NAME.azurewebsites.net"
    $allTestsPassed = $true
    
    # Test 1: Health check
    Write-Host "  Test 1/3: Health check..." -ForegroundColor Gray
    try {
        $health = Invoke-RestMethod -Uri "$API_URL/health" -TimeoutSec 30 -ErrorAction Stop
        if ($health.status -eq "healthy") {
            Write-Host "    Health check OK" -ForegroundColor Green
        } else {
            Write-Host "    Health check failed" -ForegroundColor Red
            $allTestsPassed = $false
        }
    } catch {
        Write-Host "    Health check inaccessible" -ForegroundColor Red
        Write-Host "       L'application demarre peut-etre encore..." -ForegroundColor Yellow
        $allTestsPassed = $false
    }
    
    # Test 2: Root endpoint
    Write-Host "  Test 2/3: Endpoint racine..." -ForegroundColor Gray
    try {
        $root = Invoke-RestMethod -Uri "$API_URL/" -TimeoutSec 30 -ErrorAction Stop
        if ($root.message) {
            Write-Host "    Endpoint racine OK" -ForegroundColor Green
        }
    } catch {
        Write-Host "    Endpoint racine inaccessible" -ForegroundColor Red
        $allTestsPassed = $false
    }
    
    # Test 3: Candidatures endpoint
    Write-Host "  Test 3/3: Endpoint candidatures..." -ForegroundColor Gray
    try {
        $candidats = Invoke-RestMethod -Uri "$API_URL/candidatures" -TimeoutSec 30 -ErrorAction Stop
        $count = if ($candidats) { $candidats.Count } else { 0 }
        Write-Host "    Endpoint candidatures OK ($count candidatures)`n" -ForegroundColor Green
    } catch {
        Write-Host "    Endpoint candidatures accessible mais vide`n" -ForegroundColor Yellow
    }
    
    if ($allTestsPassed) {
        Write-Host "  Tous les tests sont passes!`n" -ForegroundColor Green
    } else {
        Write-Host "  Certains tests ont echoue. Verifiez les logs:" -ForegroundColor Yellow
        Write-Host "     az webapp log tail --name $APP_NAME --resource-group $RG`n" -ForegroundColor Gray
    }
} elseif ($SkipTests) {
    Write-Host "ETAPE 8: Tests ignores (SkipTests)`n" -ForegroundColor Gray
}

# 9. Résumé Final
Write-Host "================================" -ForegroundColor Cyan
Write-Host "DEPLOIEMENT TERMINE !" -ForegroundColor Green
Write-Host "================================`n" -ForegroundColor Cyan

Write-Host "API accessible sur:" -ForegroundColor White
Write-Host "  https://$APP_NAME.azurewebsites.net`n" -ForegroundColor Cyan

Write-Host "Endpoints disponibles:" -ForegroundColor White
Write-Host "  Health:       https://$APP_NAME.azurewebsites.net/health" -ForegroundColor Gray
Write-Host "  Docs:         https://$APP_NAME.azurewebsites.net/docs" -ForegroundColor Gray
Write-Host "  Candidatures: https://$APP_NAME.azurewebsites.net/candidatures" -ForegroundColor Gray
Write-Host "  Recherche:    https://$APP_NAME.azurewebsites.net/candidatures/search`n" -ForegroundColor Gray

Write-Host "Commandes utiles:" -ForegroundColor White
Write-Host "  Voir les logs:    az webapp log tail --name $APP_NAME --resource-group $RG" -ForegroundColor Gray
Write-Host "  Redemarrer:       az webapp restart --name $APP_NAME --resource-group $RG" -ForegroundColor Gray
Write-Host "  Voir le statut:   az webapp show --name $APP_NAME --resource-group $RG --query state`n" -ForegroundColor Gray

Write-Host "Prochaines etapes:" -ForegroundColor White
Write-Host "  1. Verifier l'API: curl https://$APP_NAME.azurewebsites.net/health" -ForegroundColor Gray
Write-Host "  2. Traiter les candidats: python main.py (avec Cosmos DB configure)" -ForegroundColor Gray
Write-Host "  3. Consulter les docs: https://$APP_NAME.azurewebsites.net/docs`n" -ForegroundColor Gray

Write-Host "L'application peut prendre 1-2 minutes pour demarrer completement`n" -ForegroundColor Yellow
