# 🚀 Guide Complet - Déploiement Azure SEEG-AI

## 📋 Vue d'ensemble

Ce guide vous permettra de déployer **l'API SEEG-AI sur Azure** avec **Cosmos DB MongoDB API**.

### Architecture Finale

```
Azure App Service (API)
    ↓
Azure Cosmos DB (SEEG-AI)
    ↓
Azure Document Intelligence (OCR)
```

---

## ✅ Prérequis

- [x] Système testé et fonctionnel en local
- [x] Azure CLI installé et connecté
- [x] Docker installé
- [x] Subscription: `e44aff73-4ec5-4cf2-ad58-f8b24492970a`
- [x] Resource Group: `seeg-rg`

---

## 📊 Ressources Déjà Créées

### ✅ Cosmos DB
```
Nom: seeg-ai
Type: MongoDB API
Admin: Sevan
Location: francecentral
```

### ✅ Document Intelligence
```
Nom: seeg-document-intelligence
Endpoint: https://seeg-document-intelligence.cognitiveservices.azure.com/
Key: c692c5eb3c8c4f269af44c16ec339a7a
```

---

## 🔐 Étape 1 : Récupérer la Connection String Cosmos DB

```bash
# Se connecter à Azure
az login
az account set --subscription e44aff73-4ec5-4cf2-ad58-f8b24492970a

# Récupérer la connection string
az cosmosdb keys list \
  --name seeg-ai \
  --resource-group seeg-rg \
  --type connection-strings \
  --output json
```

**Copiez le `connectionString`** - vous en aurez besoin plus tard.

Format attendu :
```
mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000
```

---

## 🐳 Étape 2 : Container Registry

### Créer le Registry (si pas déjà fait)

```bash
ACR_NAME="seegregistry"

# Créer
az acr create \
  --resource-group seeg-rg \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Se connecter
az acr login --name $ACR_NAME
```

### Build et Push l'Image Docker

```bash
# Build localement
docker build -t seeg-ai:latest .

# Tag pour ACR
docker tag seeg-ai:latest $ACR_NAME.azurecr.io/seeg-ai:latest

# Push
docker push $ACR_NAME.azurecr.io/seeg-ai:latest

# Ou build directement dans Azure (recommandé)
az acr build \
  --registry $ACR_NAME \
  --image seeg-api:latest \
  --file Dockerfile \
  .
```

---

## 🌐 Étape 3 : Déployer l'API - Option A (App Service)

### Créer l'App Service Plan

```bash
az appservice plan create \
  --name seeg-app-plan \
  --resource-group seeg-rg \
  --is-linux \
  --sku B1 \
  --location francecentral
```

### Créer la Web App

```bash
# Récupérer les credentials ACR
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

# Créer la Web App
az webapp create \
  --resource-group seeg-rg \
  --plan seeg-app-plan \
  --name seeg-ai-api \
  --deployment-container-image-name $ACR_LOGIN_SERVER/seeg-api:latest

# Configurer le registry
az webapp config container set \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --docker-custom-image-name $ACR_LOGIN_SERVER/seeg-api:latest \
  --docker-registry-server-url https://$ACR_LOGIN_SERVER \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD
```

### Configurer les Variables d'Environnement

```bash
# Récupérer la connection string Cosmos DB (remplacez PASSWORD)
COSMOS_CONNECTION_STRING="mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000"

# Configurer toutes les variables
az webapp config appsettings set \
  --resource-group seeg-rg \
  --name seeg-ai-api \
  --settings \
    AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT="https://seeg-document-intelligence.cognitiveservices.azure.com/" \
    AZURE_DOCUMENT_INTELLIGENCE_KEY="c692c5eb3c8c4f269af44c16ec339a7a" \
    SUPABASE_URL="https://fyiitzndlqcnyluwkpqp.supabase.co" \
    SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5aWl0em5kbHFjbnlsdXdrcHFwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTUwOTE1OSwiZXhwIjoyMDcxMDg1MTU5fQ.E3R7r2Rn_0rpCdmhKAjpWsNyenkR7p-lmKP3Pnr_X38" \
    SUPABASE_BUCKET_NAME="application-documents" \
    MONGODB_CONNECTION_STRING="$COSMOS_CONNECTION_STRING" \
    MONGODB_DATABASE="SEEG-AI" \
    MONGODB_COLLECTION="candidats" \
    LOG_LEVEL="INFO" \
    WEBSITES_PORT="8000"
```

### Vérifier le Déploiement

```bash
# Voir le statut
az webapp show \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --query "{Name:name, State:state, DefaultHostName:defaultHostName}" \
  --output table

# Voir les logs
az webapp log tail \
  --name seeg-ai-api \
  --resource-group seeg-rg
```

**L'API sera accessible sur** : `https://seeg-ai-api.azurewebsites.net`

---

## 🌐 Étape 3 : Déployer l'API - Option B (Container Instances)

```bash
# Variables
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)
COSMOS_CONNECTION_STRING="mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/..."

# Créer le container
az container create \
  --resource-group seeg-rg \
  --name seeg-ai-api-container \
  --image $ACR_LOGIN_SERVER/seeg-api:latest \
  --dns-name-label seeg-ai-api \
  --ports 8000 \
  --cpu 2 \
  --memory 4 \
  --environment-variables \
    AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT="https://seeg-document-intelligence.cognitiveservices.azure.com/" \
    AZURE_DOCUMENT_INTELLIGENCE_KEY="c692c5eb3c8c4f269af44c16ec339a7a" \
    SUPABASE_URL="https://fyiitzndlqcnyluwkpqp.supabase.co" \
    SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
    SUPABASE_BUCKET_NAME="application-documents" \
    MONGODB_CONNECTION_STRING="$COSMOS_CONNECTION_STRING" \
    MONGODB_DATABASE="SEEG-AI" \
    MONGODB_COLLECTION="candidats" \
    LOG_LEVEL="INFO" \
  --registry-login-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD

# Vérifier
az container show \
  --resource-group seeg-rg \
  --name seeg-ai-api-container \
  --query "{FQDN:ipAddress.fqdn,State:instanceView.state}" \
  --output table
```

**L'API sera accessible sur** : `http://seeg-ai-api.francecentral.azurecontainer.io:8000`

---

## 🧪 Étape 4 : Tester l'API Déployée

### Test des Endpoints

```bash
# Remplacez l'URL par celle de votre déploiement
API_URL="https://seeg-ai-api.azurewebsites.net"

# Health check
curl $API_URL/health

# Toutes les candidatures
curl $API_URL/candidatures

# Recherche
curl "$API_URL/candidatures/search?first_name=Eric"
curl "$API_URL/candidatures/search?last_name=EYOGO"
```

### Avec PowerShell

```powershell
$API_URL = "https://seeg-ai-api.azurewebsites.net"

# Health check
Invoke-RestMethod -Uri "$API_URL/health"

# Candidatures
$candidatures = Invoke-RestMethod -Uri "$API_URL/candidatures"
$candidatures.Count
$candidatures[0] | Select-Object first_name, last_name

# Recherche
Invoke-RestMethod -Uri "$API_URL/candidatures/search?first_name=Eric"
```

---

## 💾 Étape 5 : Migrer les Données vers Cosmos DB

### Export depuis MongoDB Local

```bash
# Export JSON
docker exec seeg-mongodb mongoexport \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  --db SEEG-AI \
  --collection candidats \
  --out /tmp/candidats_export.json

# Copier vers l'hôte
docker cp seeg-mongodb:/tmp/candidats_export.json ./candidats_export.json
```

### Import vers Cosmos DB

```bash
# Avec la connection string Cosmos DB
mongoimport \
  --uri="mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256" \
  --db SEEG-AI \
  --collection candidats \
  --file ./candidats_export.json
```

---

## 🔄 Étape 6 : Mise à Jour de l'API

### Build et Deploy une Nouvelle Version

```bash
# Build nouvelle image
az acr build \
  --registry $ACR_NAME \
  --image seeg-api:latest \
  --file Dockerfile \
  .

# Redémarrer l'App Service
az webapp restart \
  --name seeg-ai-api \
  --resource-group seeg-rg
```

---

## 📊 Étape 7 : Monitoring (Optionnel mais Recommandé)

### Application Insights

```bash
# Créer Application Insights
az monitor app-insights component create \
  --app seeg-app-insights \
  --location francecentral \
  --resource-group seeg-rg

# Récupérer la connection string
INSIGHTS_KEY=$(az monitor app-insights component show \
  --app seeg-app-insights \
  --resource-group seeg-rg \
  --query connectionString \
  --output tsv)

# Ajouter à l'App Service
az webapp config appsettings set \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="$INSIGHTS_KEY"
```

---

## 🔒 Étape 8 : Sécurité avec Key Vault (Recommandé Production)

### Créer Key Vault

```bash
# Créer le vault
az keyvault create \
  --name seeg-keyvault \
  --resource-group seeg-rg \
  --location francecentral

# Stocker les secrets
az keyvault secret set \
  --vault-name seeg-keyvault \
  --name "DocumentIntelligenceKey" \
  --value "c692c5eb3c8c4f269af44c16ec339a7a"

az keyvault secret set \
  --vault-name seeg-keyvault \
  --name "CosmosDBConnectionString" \
  --value "$COSMOS_CONNECTION_STRING"

az keyvault secret set \
  --vault-name seeg-keyvault \
  --name "SupabaseServiceRoleKey" \
  --value "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Configurer l'Identité Managée

```bash
# Activer l'identité managée
az webapp identity assign \
  --name seeg-ai-api \
  --resource-group seeg-rg

# Récupérer le principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --query principalId \
  --output tsv)

# Donner accès au Key Vault
az keyvault set-policy \
  --name seeg-keyvault \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

### Utiliser les Secrets dans l'App Service

```bash
az webapp config appsettings set \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --settings \
    AZURE_DOCUMENT_INTELLIGENCE_KEY="@Microsoft.KeyVault(SecretUri=https://seeg-keyvault.vault.azure.net/secrets/DocumentIntelligenceKey/)" \
    MONGODB_CONNECTION_STRING="@Microsoft.KeyVault(SecretUri=https://seeg-keyvault.vault.azure.net/secrets/CosmosDBConnectionString/)"
```

---

## ✅ Étape 9 : Vérification Finale

### Test Complet

```bash
API_URL="https://seeg-ai-api.azurewebsites.net"

# 1. Health check
curl $API_URL/health

# 2. Toutes les candidatures
curl $API_URL/candidatures | jq length

# 3. Recherche
curl "$API_URL/candidatures/search?first_name=Eric" | jq '.[].last_name'

# 4. Documentation interactive
# Ouvrir: https://seeg-ai-api.azurewebsites.net/docs
```

### Vérifier les Logs

```bash
# Logs en temps réel
az webapp log tail \
  --name seeg-ai-api \
  --resource-group seeg-rg

# Ou via le portail Azure
# https://portal.azure.com → seeg-ai-api → Log stream
```

---

## 📝 Script PowerShell Tout-en-Un

Sauvegardez ce script comme `deploy_azure.ps1` :

```powershell
# Variables
$ACR_NAME = "seegregistry"
$APP_NAME = "seeg-ai-api"
$RG = "seeg-rg"

Write-Host "🚀 Déploiement SEEG-AI sur Azure" -ForegroundColor Cyan
Write-Host ""

# 1. Récupérer la connection string Cosmos DB
Write-Host "1️⃣  Récupération Connection String Cosmos DB..." -ForegroundColor Yellow
$cosmosKeys = az cosmosdb keys list `
    --name seeg-ai `
    --resource-group $RG `
    --type connection-strings `
    --output json | ConvertFrom-Json

$connectionString = $cosmosKeys.connectionStrings[0].connectionString
Write-Host "✓ Connection String récupérée" -ForegroundColor Green
Write-Host ""

# 2. Build et Push l'image
Write-Host "2️⃣  Build de l'image Docker..." -ForegroundColor Yellow
az acr build `
    --registry $ACR_NAME `
    --image seeg-api:latest `
    --file Dockerfile `
    .
Write-Host "✓ Image buildée et pushée" -ForegroundColor Green
Write-Host ""

# 3. Créer/Mettre à jour l'App Service
Write-Host "3️⃣  Configuration App Service..." -ForegroundColor Yellow

$acrServer = az acr show --name $ACR_NAME --query loginServer --output tsv
$acrUser = az acr credential show --name $ACR_NAME --query username --output tsv
$acrPass = az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv

# Vérifier si l'app existe
$appExists = az webapp show --name $APP_NAME --resource-group $RG 2>$null

if (-not $appExists) {
    Write-Host "Création de l'App Service..." -ForegroundColor Yellow
    
    # Créer le plan
    az appservice plan create `
        --name seeg-app-plan `
        --resource-group $RG `
        --is-linux `
        --sku B1 `
        --location francecentral
    
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
}

# Configurer les variables d'environnement
Write-Host "Configuration des variables..." -ForegroundColor Yellow
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

# 4. Redémarrer
Write-Host "4️⃣  Redémarrage de l'application..." -ForegroundColor Yellow
az webapp restart --name $APP_NAME --resource-group $RG
Write-Host "✓ Application redémarrée" -ForegroundColor Green
Write-Host ""

# 5. Afficher l'URL
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ Déploiement terminé !" -ForegroundColor Green
Write-Host ""
Write-Host "API accessible sur:" -ForegroundColor White
Write-Host "  https://$APP_NAME.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "Endpoints:" -ForegroundColor White
Write-Host "  Health: https://$APP_NAME.azurewebsites.net/health" -ForegroundColor Gray
Write-Host "  Docs: https://$APP_NAME.azurewebsites.net/docs" -ForegroundColor Gray
Write-Host "  Candidatures: https://$APP_NAME.azurewebsites.net/candidatures" -ForegroundColor Gray
Write-Host ""

