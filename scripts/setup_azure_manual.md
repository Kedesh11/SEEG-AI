# 🔷 Guide Manuel - Configuration Azure avec Azure CLI

## 📋 Prérequis

1. **Installer Azure CLI** : https://aka.ms/installazurecliwindows
2. **Compte Azure** avec accès administrateur
3. **PowerShell** ou **Terminal** ouvert

---

## 🚀 Étape par Étape

### 1️⃣ Connexion à Azure

```bash
# Se connecter
az login

# Vérifier le compte connecté
az account show

# Lister les abonnements disponibles
az account list --output table

# Changer d'abonnement si nécessaire
az account set --subscription "VOTRE_ABONNEMENT_ID"
```

**✅ Notez** : Votre abonnement ID : `e44aff73-4ec5-4cf2-ad58-f8b24492970a`

---

### 2️⃣ Resource Group

#### Lister les Resource Groups existants

```bash
az group list --output table
```

#### Utiliser un RG existant OU en créer un nouveau

```bash
# Option A: Utiliser "seeg-rg" existant (recommandé)
# Rien à faire

# Option B: Créer un nouveau RG
az group create --name seeg-rg --location francecentral
```

**✅ Notez** : Nom du Resource Group : `seeg-rg`

---

### 3️⃣ Azure Document Intelligence (OCR)

#### Vérifier si une ressource existe déjà

```bash
# Lister toutes les ressources Cognitive Services
az cognitiveservices account list \
  --resource-group seeg-rg \
  --query "[?kind=='FormRecognizer']" \
  --output table
```

#### Option A : Utiliser une ressource existante

Si vous avez déjà une ressource, récupérez ses informations :

```bash
# Remplacez NOM_RESSOURCE par le nom trouvé ci-dessus
RESOURCE_NAME="VOTRE_NOM_RESSOURCE"

# Récupérer l'endpoint
az cognitiveservices account show \
  --name $RESOURCE_NAME \
  --resource-group seeg-rg \
  --query "properties.endpoint" \
  --output tsv

# Récupérer la clé
az cognitiveservices account keys list \
  --name $RESOURCE_NAME \
  --resource-group seeg-rg \
  --query "key1" \
  --output tsv
```

#### Option B : Créer une nouvelle ressource

```bash
# Définir le nom
RESOURCE_NAME="seeg-document-intelligence"

# Créer la ressource (SKU S0 pour production, F0 pour gratuit)
az cognitiveservices account create \
  --name $RESOURCE_NAME \
  --resource-group seeg-rg \
  --kind FormRecognizer \
  --sku S0 \
  --location francecentral \
  --yes

# Récupérer l'endpoint
az cognitiveservices account show \
  --name $RESOURCE_NAME \
  --resource-group seeg-rg \
  --query "properties.endpoint" \
  --output tsv

# Récupérer la clé
az cognitiveservices account keys list \
  --name $RESOURCE_NAME \
  --resource-group seeg-rg \
  --query "key1" \
  --output tsv
```

**✅ Notez** :
- Endpoint : `https://seeg-document-intelligence.cognitiveservices.azure.com/`
- Key : `VOTRE_CLE_ICI`

---

### 4️⃣ Azure Cosmos DB (MongoDB API)

#### Vérifier si un compte existe

```bash
# Lister les comptes Cosmos DB
az cosmosdb list \
  --resource-group seeg-rg \
  --output table
```

#### Option A : Utiliser le compte existant "seeg-ai"

```bash
# Récupérer la chaîne de connexion
az cosmosdb keys list \
  --name seeg-ai \
  --resource-group seeg-rg \
  --type connection-strings \
  --output json
```

**La sortie ressemblera à** :

```json
{
  "connectionStrings": [
    {
      "connectionString": "mongodb+srv://USERNAME:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256...",
      "description": "Primary MongoDB Connection String"
    }
  ]
}
```

#### Option B : Créer un nouveau compte (⚠️ Prend 5-10 minutes)

```bash
# Créer le compte
az cosmosdb create \
  --name seeg-ai \
  --resource-group seeg-rg \
  --kind MongoDB \
  --server-version 7.0 \
  --locations regionName=francecentral \
  --default-consistency-level Session

# Attendre que la création se termine...

# Récupérer la chaîne de connexion
az cosmosdb keys list \
  --name seeg-ai \
  --resource-group seeg-rg \
  --type connection-strings \
  --output json
```

**✅ Notez** :
- Connection String : `mongodb+srv://...`
- Username (dans la chaîne) : `Sevan`
- Password : À extraire de la chaîne de connexion

---

### 5️⃣ Créer le fichier .env

Créez un fichier `.env` à la racine du projet avec les valeurs récupérées :

```env
# ====================================
# Azure Document Intelligence
# ====================================
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://seeg-document-intelligence.cognitiveservices.azure.com/
AZURE_DOCUMENT_INTELLIGENCE_KEY=VOTRE_CLE_RECUPEREE_ETAPE_3

# ====================================
# Supabase
# ====================================
SUPABASE_URL=https://fyiitzndlqcnyluwkpqp.supabase.co
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_BUCKET_NAME=candidats-documents

# ====================================
# MongoDB / Cosmos DB
# ====================================

# OPTION 1: Production avec Cosmos DB
MONGODB_CONNECTION_STRING=VOTRE_CONNECTION_STRING_ETAPE_4
MONGODB_DATABASE=SEEG-AI
MONGODB_COLLECTION=candidats

# OPTION 2: Développement local (Docker)
# Décommentez ci-dessous et commentez ci-dessus pour utiliser MongoDB local
# MONGODB_CONNECTION_STRING=mongodb://Sevan:Sevan@Seeg@localhost:27017
# MONGODB_DATABASE=SEEG-AI
# MONGODB_COLLECTION=candidats

# ====================================
# Application Settings
# ====================================
LOG_LEVEL=INFO
DATA_FOLDER=./data
TEMP_FOLDER=./temp
API_HOST=0.0.0.0
API_PORT=8000
```

---

## 🎯 Commandes de Vérification

### Vérifier les ressources créées

```bash
# Lister toutes les ressources du RG
az resource list --resource-group seeg-rg --output table

# Vérifier Document Intelligence
az cognitiveservices account show \
  --name seeg-document-intelligence \
  --resource-group seeg-rg

# Vérifier Cosmos DB
az cosmosdb show \
  --name seeg-ai \
  --resource-group seeg-rg
```

### Tester la connexion

```bash
# Tester l'API Document Intelligence
curl -X POST "VOTRE_ENDPOINT/formrecognizer/documentModels/prebuilt-read:analyze?api-version=2023-07-31" \
  -H "Ocp-Apim-Subscription-Key: VOTRE_CLE" \
  -H "Content-Type: application/json"

# Tester MongoDB local
docker exec -it seeg-mongodb mongosh -u Sevan -p "Sevan@Seeg" SEEG-AI
```

---

## 📊 Informations Importantes

### Coûts Estimés (par mois)

| Service | SKU | Coût Estimé |
|---------|-----|-------------|
| Document Intelligence | S0 | ~$1.50 par 1000 pages |
| Document Intelligence | F0 | Gratuit (500 pages/mois) |
| Cosmos DB | Serverless | ~$25-50 (dépend utilisation) |
| MongoDB Local | Docker | Gratuit |

### Recommandations

1. **Développement** : Utilisez MongoDB local (Docker) + Document Intelligence F0
2. **Production** : Utilisez Cosmos DB + Document Intelligence S0
3. **Sécurité** : Ne committez JAMAIS le fichier `.env` dans Git

---

## 🔒 Sécurité - Azure Key Vault (Optionnel)

Pour une sécurité maximale en production :

```bash
# Créer un Key Vault
az keyvault create \
  --name seeg-keyvault \
  --resource-group seeg-rg \
  --location francecentral

# Stocker les secrets
az keyvault secret set \
  --vault-name seeg-keyvault \
  --name "DocumentIntelligenceKey" \
  --value "VOTRE_CLE"

az keyvault secret set \
  --vault-name seeg-keyvault \
  --name "CosmosDBConnectionString" \
  --value "VOTRE_CONNECTION_STRING"

# Récupérer un secret
az keyvault secret show \
  --vault-name seeg-keyvault \
  --name "DocumentIntelligenceKey" \
  --query "value" \
  --output tsv
```

---

## ✅ Checklist Finale

Avant de lancer l'application :

- [ ] Azure CLI installé et fonctionnel
- [ ] Connecté à Azure (`az login`)
- [ ] Resource Group existe (`seeg-rg`)
- [ ] Document Intelligence créé et clé récupérée
- [ ] Cosmos DB créé OU MongoDB local prêt
- [ ] Fichier `.env` créé avec toutes les valeurs
- [ ] Docker démarré (`docker-compose up -d`)
- [ ] Dépendances Python installées (`pip install -r requirements.txt`)

---

## 🆘 Dépannage

### Erreur "Resource already exists"

```bash
# Vérifier si la ressource existe
az cognitiveservices account show --name VOTRE_NOM --resource-group seeg-rg
```

### Erreur d'autorisation

```bash
# Vérifier votre rôle
az role assignment list --assignee "VOTRE_EMAIL" --output table

# Demander les permissions Owner ou Contributor
```

### Connection timeout Cosmos DB

```bash
# Vérifier le firewall
az cosmosdb show \
  --name seeg-ai \
  --resource-group seeg-rg \
  --query "ipRules"

# Ajouter votre IP
az cosmosdb update \
  --name seeg-ai \
  --resource-group seeg-rg \
  --ip-range-filter "VOTRE_IP"
```

---

**Guide créé pour SEEG-AI** 🚀

