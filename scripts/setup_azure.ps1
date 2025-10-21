# Script de configuration Azure pour SEEG-AI (Windows PowerShell)
# Ce script vous guide pour récupérer les informations Azure nécessaires

Write-Host "🔷 Configuration Azure - SEEG-AI" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Fonction pour afficher des étapes
function Show-Step {
    param($number, $title)
    Write-Host ""
    Write-Host "[$number] $title" -ForegroundColor Yellow
    Write-Host ("-" * 60) -ForegroundColor Gray
}

# Vérifier si Azure CLI est installé
Show-Step "0" "Vérification Azure CLI"
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "✓ Azure CLI installé: $($azVersion.'azure-cli')" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure CLI n'est pas installé" -ForegroundColor Red
    Write-Host "Installez-le depuis: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

# Étape 1: Connexion à Azure
Show-Step "1" "Connexion à Azure"
Write-Host "Exécutez cette commande pour vous connecter :" -ForegroundColor White
Write-Host "az login" -ForegroundColor Cyan
Write-Host ""
Read-Host "Appuyez sur Entrée après vous être connecté"

# Vérifier la connexion
$account = az account show --output json 2>$null | ConvertFrom-Json
if ($account) {
    Write-Host "✓ Connecté en tant que: $($account.user.name)" -ForegroundColor Green
    Write-Host "✓ Abonnement: $($account.name)" -ForegroundColor Green
    Write-Host "✓ ID: $($account.id)" -ForegroundColor Green
}
else {
    Write-Host "❌ Non connecté. Exécutez 'az login' d'abord." -ForegroundColor Red
    exit 1
}

# Étape 2: Lister les Resource Groups
Show-Step "2" "Resource Groups Disponibles"
Write-Host "Liste de vos resource groups :" -ForegroundColor White
az group list --query "[].{Name:name, Location:location}" --output table

Write-Host ""
$rgName = Read-Host "Entrez le nom du resource group à utiliser (ou créer)"

# Vérifier si le RG existe
$rgExists = az group exists --name $rgName
if ($rgExists -eq "false") {
    Write-Host "⚠️  Le resource group '$rgName' n'existe pas." -ForegroundColor Yellow
    $createRg = Read-Host "Voulez-vous le créer? (oui/non)"
    if ($createRg -eq "oui") {
        $location = Read-Host "Entrez la location (ex: francecentral, westeurope)"
        az group create --name $rgName --location $location
        Write-Host "✓ Resource group créé" -ForegroundColor Green
    }
}

# Étape 3: Azure Document Intelligence
Show-Step "3" "Azure Document Intelligence (OCR)"

Write-Host "Recherche des ressources Document Intelligence existantes..." -ForegroundColor White
$docIntelResources = az cognitiveservices account list `
    --resource-group $rgName `
    --query "[?kind=='FormRecognizer'].{Name:name, Location:location, Sku:sku.name}" `
    --output json 2>$null | ConvertFrom-Json

if ($docIntelResources) {
    Write-Host "✓ Ressources trouvées :" -ForegroundColor Green
    $docIntelResources | ForEach-Object { 
        Write-Host "  - $($_.Name) ($($_.Location)) - SKU: $($_.Sku)" -ForegroundColor Cyan
    }
    Write-Host ""
    $useExisting = Read-Host "Utiliser une ressource existante? (oui/non)"
    
    if ($useExisting -eq "oui") {
        $docIntelName = Read-Host "Entrez le nom de la ressource à utiliser"
    }
    else {
        $docIntelName = $null
    }
}
else {
    Write-Host "⚠️  Aucune ressource Document Intelligence trouvée." -ForegroundColor Yellow
    $docIntelName = $null
}

if (-not $docIntelName) {
    Write-Host ""
    Write-Host "Création d'une nouvelle ressource Document Intelligence..." -ForegroundColor Yellow
    $docIntelName = Read-Host "Nom de la ressource (ex: seeg-document-intelligence)"
    $location = Read-Host "Location (ex: francecentral, westeurope)"
    $sku = Read-Host "SKU (S0 pour production, F0 pour gratuit)"
    
    Write-Host "Création en cours..." -ForegroundColor Yellow
    az cognitiveservices account create `
        --name $docIntelName `
        --resource-group $rgName `
        --kind FormRecognizer `
        --sku $sku `
        --location $location `
        --yes
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Ressource créée avec succès" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Erreur lors de la création" -ForegroundColor Red
        exit 1
    }
}

# Récupérer l'endpoint et la clé
Write-Host ""
Write-Host "Récupération des informations..." -ForegroundColor Yellow

$docIntelEndpoint = az cognitiveservices account show `
    --name $docIntelName `
    --resource-group $rgName `
    --query "properties.endpoint" `
    --output tsv

$docIntelKey = az cognitiveservices account keys list `
    --name $docIntelName `
    --resource-group $rgName `
    --query "key1" `
    --output tsv

Write-Host "✓ Endpoint: $docIntelEndpoint" -ForegroundColor Green
Write-Host "✓ Key: $($docIntelKey.Substring(0,10))..." -ForegroundColor Green

# Étape 4: Azure Cosmos DB
Show-Step "4" "Azure Cosmos DB (MongoDB API)"

Write-Host "Recherche des bases Cosmos DB existantes..." -ForegroundColor White
$cosmosAccounts = az cosmosdb list `
    --resource-group $rgName `
    --query "[].{Name:name, Location:location}" `
    --output json 2>$null | ConvertFrom-Json

if ($cosmosAccounts) {
    Write-Host "✓ Comptes Cosmos DB trouvés :" -ForegroundColor Green
    $cosmosAccounts | ForEach-Object { 
        Write-Host "  - $($_.Name) ($($_.Location))" -ForegroundColor Cyan
    }
    Write-Host ""
    $cosmosName = Read-Host "Entrez le nom du compte à utiliser (ou laissez vide pour en créer un)"
}
else {
    Write-Host "⚠️  Aucun compte Cosmos DB trouvé." -ForegroundColor Yellow
    $cosmosName = $null
}

if (-not $cosmosName -or $cosmosName -eq "") {
    Write-Host ""
    Write-Host "⚠️  Création d'un Cosmos DB (MongoDB API) peut prendre 5-10 minutes" -ForegroundColor Yellow
    $createCosmos = Read-Host "Voulez-vous créer un nouveau compte Cosmos DB? (oui/non)"
    
    if ($createCosmos -eq "oui") {
        $cosmosName = Read-Host "Nom du compte (ex: seeg-ai)"
        $location = Read-Host "Location (ex: francecentral)"
        
        Write-Host "Création en cours (cela peut prendre plusieurs minutes)..." -ForegroundColor Yellow
        az cosmosdb create `
            --name $cosmosName `
            --resource-group $rgName `
            --kind MongoDB `
            --server-version 7.0 `
            --locations regionName=$location `
            --default-consistency-level Session
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Cosmos DB créé avec succès" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Erreur lors de la création" -ForegroundColor Red
            $cosmosName = $null
        }
    }
    else {
        $cosmosName = $null
    }
}

$cosmosConnectionString = $null
if ($cosmosName) {
    Write-Host ""
    Write-Host "Récupération de la chaîne de connexion..." -ForegroundColor Yellow
    
    $cosmosKeys = az cosmosdb keys list `
        --name $cosmosName `
        --resource-group $rgName `
        --type connection-strings `
        --output json | ConvertFrom-Json
    
    $cosmosConnectionString = $cosmosKeys.connectionStrings[0].connectionString
    
    Write-Host "✓ Chaîne de connexion récupérée" -ForegroundColor Green
}

# Étape 5: Génération du fichier .env
Show-Step "5" "Génération du fichier .env"

$envContent = @"
# ====================================
# Azure Document Intelligence
# ====================================
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=$docIntelEndpoint
AZURE_DOCUMENT_INTELLIGENCE_KEY=$docIntelKey

# ====================================
# Supabase
# ====================================
SUPABASE_URL=https://fyiitzndlqcnyluwkpqp.supabase.co
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_BUCKET_NAME=candidats-documents

# ====================================
# MongoDB / Cosmos DB
# ====================================

"@

if ($cosmosConnectionString) {
    $envContent += @"
# PRODUCTION avec Azure Cosmos DB
MONGODB_CONNECTION_STRING=$cosmosConnectionString
MONGODB_DATABASE=SEEG-AI
MONGODB_COLLECTION=candidats

# Pour développement local (commenter la ligne ci-dessus et décommenter ci-dessous)
# MONGODB_CONNECTION_STRING=mongodb://Sevan:Sevan@Seeg@localhost:27017
"@
}
else {
    $envContent += @"
# DÉVELOPPEMENT LOCAL (Docker)
MONGODB_CONNECTION_STRING=mongodb://Sevan:Sevan@Seeg@localhost:27017
MONGODB_DATABASE=SEEG-AI
MONGODB_COLLECTION=candidats

# Pour production Cosmos DB (remplir après création)
# MONGODB_CONNECTION_STRING=mongodb+srv://...
"@
}

$envContent += @"


# ====================================
# Application Settings
# ====================================
LOG_LEVEL=INFO
DATA_FOLDER=./data
TEMP_FOLDER=./temp
API_HOST=0.0.0.0
API_PORT=8000
"@

# Sauvegarder le fichier
$envContent | Out-File -FilePath ".env" -Encoding UTF8

Write-Host "✓ Fichier .env créé avec succès!" -ForegroundColor Green

# Résumé
Show-Step "✅" "Résumé de la Configuration"

Write-Host "Resource Group:" -ForegroundColor White
Write-Host "  $rgName" -ForegroundColor Cyan
Write-Host ""

Write-Host "Document Intelligence:" -ForegroundColor White
Write-Host "  Nom: $docIntelName" -ForegroundColor Cyan
Write-Host "  Endpoint: $docIntelEndpoint" -ForegroundColor Cyan
Write-Host ""

if ($cosmosName) {
    Write-Host "Cosmos DB:" -ForegroundColor White
    Write-Host "  Nom: $cosmosName" -ForegroundColor Cyan
    Write-Host "  Connection: Configurée dans .env" -ForegroundColor Cyan
}
else {
    Write-Host "Cosmos DB:" -ForegroundColor White
    Write-Host "  Non configuré - utilisation de MongoDB local" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "✅ Configuration terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes:" -ForegroundColor White
Write-Host "  1. Vérifiez le fichier .env créé" -ForegroundColor Gray
Write-Host "  2. Lancez: docker-compose up -d" -ForegroundColor Gray
Write-Host "  3. Testez: python main.py" -ForegroundColor Gray
Write-Host ""

