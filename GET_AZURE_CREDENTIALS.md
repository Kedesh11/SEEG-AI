# 🔑 Récupération des Credentials Azure

## 📋 Informations Déjà Connues

Voici les informations de votre compte Azure récupérées de nos conversations :

- **Subscription ID** : `e44aff73-4ec5-4cf2-ad58-f8b24492970a`
- **Resource Group** : `seeg-rg`
- **Location** : `francecentral`
- **Cosmos DB Account** : `seeg-ai`
- **Cosmos DB Admin** : `Sevan`
- **Supabase URL** : `https://fyiitzndlqcnyluwkpqp.supabase.co`
- **Supabase Key** : ✅ Déjà configuré

---

## 🎯 Ce qu'il Reste à Récupérer

### 1️⃣ Azure Document Intelligence

#### Étape A : Se connecter à Azure

```bash
az login
az account set --subscription e44aff73-4ec5-4cf2-ad58-f8b24492970a
```

#### Étape B : Vérifier si une ressource existe

```bash
az cognitiveservices account list \
  --resource-group seeg-rg \
  --query "[?kind=='FormRecognizer'].{Name:name, Location:location, Endpoint:properties.endpoint}" \
  --output table
```

**Résultat attendu** :
```
Name                           Location       Endpoint
-----------------------------  -------------  -----------------------------------------------
seeg-document-intelligence     francecentral  https://seeg-document-intelligence.cognitive...
```

#### Étape C : Récupérer l'Endpoint

```bash
# Remplacez NOM_RESSOURCE par le nom trouvé ci-dessus
az cognitiveservices account show \
  --name NOM_RESSOURCE \
  --resource-group seeg-rg \
  --query "properties.endpoint" \
  --output tsv
```

**Copiez le résultat** → `AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT`

#### Étape D : Récupérer la Clé

```bash
az cognitiveservices account keys list \
  --name NOM_RESSOURCE \
  --resource-group seeg-rg \
  --query "key1" \
  --output tsv
```

**Copiez le résultat** → `AZURE_DOCUMENT_INTELLIGENCE_KEY`

---

### 2️⃣ Azure Cosmos DB - Connection String

#### Récupérer la chaîne de connexion complète

```bash
az cosmosdb keys list \
  --name seeg-ai \
  --resource-group seeg-rg \
  --type connection-strings \
  --output json
```

**Résultat attendu** (format JSON) :
```json
{
  "connectionStrings": [
    {
      "connectionString": "mongodb+srv://Sevan:REAL_PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000",
      "description": "Primary MongoDB Connection String"
    }
  ]
}
```

**Copiez le `connectionString`** → `MONGODB_CONNECTION_STRING`

---

## 📝 Mise à Jour du Fichier .env

### Étape 1 : Renommer le fichier

```bash
# Renommez .env.seeg en .env
mv .env.seeg .env
# ou sur Windows
ren .env.seeg .env
```

### Étape 2 : Éditer le fichier .env

Ouvrez le fichier `.env` et remplacez :

```env
# Remplacez ces 3 lignes avec les valeurs récupérées :

AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://VOTRE_ENDPOINT_ICI
AZURE_DOCUMENT_INTELLIGENCE_KEY=VOTRE_CLE_ICI

MONGODB_CONNECTION_STRING=mongodb+srv://Sevan:VOTRE_PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000
```

---

## ✅ Vérification

### Tester la connexion Azure Document Intelligence

```bash
# PowerShell
$endpoint = "VOTRE_ENDPOINT"
$key = "VOTRE_CLE"

curl -X GET "$endpoint/formrecognizer/documentModels?api-version=2023-07-31" `
  -H "Ocp-Apim-Subscription-Key: $key"
```

**Résultat attendu** : Une liste de modèles disponibles (JSON)

### Tester la connexion Cosmos DB

```bash
# Avec mongosh (si installé localement)
mongosh "VOTRE_CONNECTION_STRING_COMPLETE"

# Ou via Docker avec l'application
docker-compose up -d
python -c "from src.database.mongodb_client import mongodb_client; mongodb_client.connect(); print('✓ MongoDB connecté')"
```

---

## 🚀 Script PowerShell Tout-en-Un

Créez un fichier `get_credentials.ps1` et exécutez-le :

```powershell
# Se connecter
az login
az account set --subscription e44aff73-4ec5-4cf2-ad58-f8b24492970a

Write-Host "=== Azure Document Intelligence ===" -ForegroundColor Cyan
$docIntelResources = az cognitiveservices account list `
    --resource-group seeg-rg `
    --query "[?kind=='FormRecognizer'].name" `
    --output json | ConvertFrom-Json

if ($docIntelResources) {
    $resourceName = $docIntelResources[0]
    Write-Host "Ressource trouvée: $resourceName" -ForegroundColor Green
    
    $endpoint = az cognitiveservices account show `
        --name $resourceName `
        --resource-group seeg-rg `
        --query "properties.endpoint" `
        --output tsv
    
    $key = az cognitiveservices account keys list `
        --name $resourceName `
        --resource-group seeg-rg `
        --query "key1" `
        --output tsv
    
    Write-Host "Endpoint: $endpoint" -ForegroundColor Yellow
    Write-Host "Key: $key" -ForegroundColor Yellow
} else {
    Write-Host "Aucune ressource Document Intelligence trouvée" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Cosmos DB ===" -ForegroundColor Cyan
$cosmosConnection = az cosmosdb keys list `
    --name seeg-ai `
    --resource-group seeg-rg `
    --type connection-strings `
    --output json | ConvertFrom-Json

$connectionString = $cosmosConnection.connectionStrings[0].connectionString
Write-Host "Connection String: $connectionString" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== Copiez ces valeurs dans votre .env ===" -ForegroundColor Green
```

---

## 📞 Aide Rapide

### Si Document Intelligence n'existe pas

```bash
# Créer une nouvelle ressource
az cognitiveservices account create \
  --name seeg-document-intelligence \
  --resource-group seeg-rg \
  --kind FormRecognizer \
  --sku S0 \
  --location francecentral \
  --yes
```

### Si Cosmos DB est inaccessible

```bash
# Vérifier le statut
az cosmosdb show \
  --name seeg-ai \
  --resource-group seeg-rg \
  --query "{Name:name, State:properties.provisioningState}"

# Ajouter votre IP au firewall
az cosmosdb update \
  --name seeg-ai \
  --resource-group seeg-rg \
  --ip-range-filter "0.0.0.0/0"  # Attention: ouvre à tous (dev seulement)
```

---

## 🎯 Résumé

**Ce dont vous avez besoin** :

1. ✅ Se connecter : `az login`
2. 🔍 Trouver la ressource Document Intelligence
3. 📋 Récupérer Endpoint + Key
4. 🔑 Récupérer Connection String Cosmos DB
5. ✏️ Mettre à jour `.env`
6. ✅ Tester les connexions

---

**Temps estimé** : 5 minutes ⏱️

