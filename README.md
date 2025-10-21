# SEEG-AI - Système de Traitement Automatisé de Candidatures

## 📋 Table des Matières

1. [Description](#description)
2. [Démarrage Rapide (3 minutes)](#démarrage-rapide)
3. [Architecture](#architecture)
4. [Installation Complète](#installation-complète)
5. [Configuration](#configuration)
6. [MongoDB en Container](#mongodb-en-container)
7. [Utilisation](#utilisation)
8. [API REST](#api-rest)
9. [Déploiement sur Azure](#déploiement-sur-azure)
10. [Tests](#tests)
11. [Scripts Utilitaires](#scripts-utilitaires)
12. [Dépannage](#dépannage)
13. [Architecture Technique Détaillée](#architecture-technique-détaillée)
14. [Contribution](#contribution)

---

## 📋 Description

SEEG-AI est une solution complète de traitement automatisé de candidatures avec :
- **Extraction OCR** via Azure Document Intelligence (meilleure API disponible)
- **Stockage structuré** dans MongoDB/Azure Cosmos DB
- **API REST** pour consulter les candidatures
- **MongoDB containerisé** (pas d'installation locale nécessaire)
- **Architecture dockerisée** pour un déploiement simplifié

### ✨ Fonctionnalités Principales

✅ **Script de traitement** : Lit les JSON, télécharge les documents, extrait le texte (OCR), stocke dans MongoDB  
✅ **API REST FastAPI** : 4 endpoints publics pour consulter/rechercher les candidatures  
✅ **Idempotence** : Pas de duplication, traitement peut être relancé  
✅ **MongoDB en container** : Aucune installation locale requise  
✅ **Interface web** : Mongo Express pour visualiser les données  
✅ **Tests complets** : Unitaires et d'intégration  
✅ **Documentation interactive** : Swagger UI automatique  

---

## 🚀 Démarrage Rapide

### En 3 Minutes, Votre Système est Opérationnel !

#### Étape 1️⃣ : Configuration (1 minute)

Créer un fichier `.env` à la racine du projet :

```env
# Azure Document Intelligence (obligatoire)
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://VOTRE_RESSOURCE.cognitiveservices.azure.com/
AZURE_DOCUMENT_INTELLIGENCE_KEY=votre_clé_azure

# Supabase (obligatoire)
SUPABASE_URL=https://fyiitzndlqcnyluwkpqp.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5aWl0em5kbHFjbnlsdXdrcHFwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTUwOTE1OSwiZXhwIjoyMDcxMDg1MTU5fQ.E3R7r2Rn_0rpCdmhKAjpWsNyenkR7p-lmKP3Pnr_X38

# MongoDB local (pour développement)
MONGODB_CONNECTION_STRING=mongodb://admin:adminpassword@localhost:27017
MONGODB_DATABASE=seeg_candidatures
MONGODB_COLLECTION=candidats
```

💡 **Astuce** : Copiez `env_template.txt` vers `.env` et remplissez vos credentials.

#### Étape 2️⃣ : Démarrage (1 minute)

```bash
# Lancez Docker (MongoDB + API + Interface Web)
docker-compose up -d

# Attendez 30 secondes que tout démarre...
```

#### Étape 3️⃣ : Test (30 secondes)

```bash
# Testez que tout fonctionne
curl http://localhost:8000/health

# Ou ouvrez dans votre navigateur : http://localhost:8000
```

### 🎉 C'est fait ! Votre système tourne !

**Accès aux services :**

| Service | URL | Login/Password |
|---------|-----|----------------|
| **API Documentation** | http://localhost:8000/docs | - |
| **API Endpoint** | http://localhost:8000/candidatures | - |
| **Mongo Express** | http://localhost:8081 | admin / admin |
| **MongoDB** | localhost:27017 | admin / adminpassword |

---

## 🏗️ Architecture

### Structure du Projet

```
SEEG-AI/
├── src/                          # Code source
│   ├── api/                     # API FastAPI
│   │   ├── app.py              # Routes et endpoints
│   │   └── __init__.py
│   ├── database/                # Connexion MongoDB
│   │   ├── mongodb_client.py   # Client MongoDB/Cosmos DB
│   │   └── __init__.py
│   ├── services/                # Services externes
│   │   ├── azure_ocr.py        # Azure Document Intelligence
│   │   ├── supabase_client.py  # Client Supabase
│   │   └── __init__.py
│   ├── processor/               # Traitement des candidatures
│   │   ├── candidature_processor.py
│   │   └── __init__.py
│   ├── config.py               # Configuration centralisée
│   ├── logger.py               # Système de logging
│   └── models.py               # Modèles Pydantic
├── tests/                       # Tests unitaires et d'intégration
├── data/                        # Fichiers JSON candidats
├── temp/                        # Fichiers temporaires
├── logs/                        # Logs application
├── scripts/                     # Scripts utilitaires
├── main.py                      # Script de traitement
├── run_api.py                  # Lancement de l'API
├── Dockerfile                   # Image Docker
├── docker-compose.yml          # Orchestration services
├── requirements.txt            # Dépendances Python
└── README.md                   # Cette documentation
```

### Flux de Traitement

```
Fichier JSON (data/) 
    ↓
Lecture et extraction métadonnées
    ↓
Téléchargement documents (Supabase)
    ↓
Extraction texte OCR (Azure Document Intelligence)
    ↓
Validation et normalisation (Pydantic)
    ↓
Stockage MongoDB (Upsert - idempotent)
```

### Architecture Système

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   Client    │─────▶│  API FastAPI │─────▶│   MongoDB /     │
│  (Browser)  │◀─────│  (Port 8000) │◀─────│   Cosmos DB     │
└─────────────┘      └──────┬───────┘      └─────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  Processor    │
                    │  Candidature  │
                    └───────┬───────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
        ┌──────────┐            ┌──────────┐
        │ Supabase │            │  Azure   │
        │ Storage  │            │ Document │
        │          │            │  Intel.  │
        └──────────┘            └──────────┘
```

---

## 💻 Installation Complète

### Prérequis

- Python 3.11+
- Docker et Docker Compose
- Compte Azure avec Document Intelligence
- Compte Supabase
- Git

### Installation Locale

#### 1. Cloner le projet

```bash
git clone <repository-url>
cd SEEG-AI
```

#### 2. Créer l'environnement virtuel

**Linux/Mac :**
```bash
python -m venv env
source env/bin/activate
pip install -r requirements.txt
```

**Windows :**
```powershell
python -m venv env
.\env\Scripts\activate
pip install -r requirements.txt
```

**Ou utiliser les scripts automatiques :**

```bash
# Linux/Mac
chmod +x scripts/setup_env.sh
./scripts/setup_env.sh

# Windows
.\scripts\setup_env.ps1
```

#### 3. Créer les dossiers nécessaires

```bash
mkdir -p data temp logs
```

#### 4. Vérifier l'installation

```bash
python scripts/check_setup.py
```

---

## ⚙️ Configuration

### Variables d'Environnement

Créer un fichier `.env` à la racine :

```env
# ====================================
# Azure Document Intelligence
# ====================================
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://YOUR_RESOURCE.cognitiveservices.azure.com/
AZURE_DOCUMENT_INTELLIGENCE_KEY=votre_cle_azure_32_caracteres

# ====================================
# Supabase
# ====================================
SUPABASE_URL=https://fyiitzndlqcnyluwkpqp.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5aWl0em5kbHFjbnlsdXdrcHFwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTUwOTE1OSwiZXhwIjoyMDcxMDg1MTU5fQ.E3R7r2Rn_0rpCdmhKAjpWsNyenkR7p-lmKP3Pnr_X38

# ====================================
# MongoDB / Cosmos DB
# ====================================

# Pour DÉVELOPPEMENT LOCAL (avec Docker)
MONGODB_CONNECTION_STRING=mongodb://admin:adminpassword@localhost:27017
MONGODB_DATABASE=seeg_candidatures
MONGODB_COLLECTION=candidats

# Pour PRODUCTION avec Azure Cosmos DB
# MONGODB_CONNECTION_STRING=mongodb+srv://Sevan:<password>@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000
# MONGODB_USERNAME=Sevan
# MONGODB_PASSWORD=votre_mot_de_passe_cosmos_db

# ====================================
# Application Settings
# ====================================
LOG_LEVEL=INFO
DATA_FOLDER=./data
TEMP_FOLDER=./temp
API_HOST=0.0.0.0
API_PORT=8000
```

### Informations Azure Cosmos DB

```json
{
  "id": "seeg-ai",
  "location": "francecentral",
  "connectionString": "mongodb+srv://<user>:<password>@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000",
  "administratorLogin": "Sevan",
  "serverVersion": "8.0"
}
```

---

## 🗄️ MongoDB en Container

### Pourquoi en Container ?

✅ **Pas d'installation locale** : MongoDB tourne dans Docker  
✅ **Persistance des données** : Les données restent après arrêt  
✅ **Isolation** : N'affecte pas votre système  
✅ **Facilité** : Une seule commande pour démarrer  
✅ **Portable** : Fonctionne partout (Windows/Linux/Mac)  

### Configuration MongoDB Container

```yaml
Image: mongo:7.0
Container: seeg-mongodb
Port: 27017
Username: admin
Password: adminpassword
Database: seeg_candidatures
Collection: candidats
```

### Commandes MongoDB

#### Démarrage

```bash
# Démarrer uniquement MongoDB
docker-compose up -d mongodb

# Ou démarrer tous les services (MongoDB + API + Mongo Express)
docker-compose up -d

# Vérifier que MongoDB tourne
docker-compose ps mongodb

# Voir les logs
docker-compose logs -f mongodb
```

#### Arrêt

```bash
# Arrêter MongoDB
docker-compose stop mongodb

# Arrêter et supprimer le container (données préservées)
docker-compose down

# Tout supprimer (⚠️ destructif - supprime aussi les données)
docker-compose down -v
```

#### Accès Shell MongoDB

```bash
# Via script (Linux/Mac)
./scripts/mongodb_cli.sh

# Via script (Windows) ou commande directe
docker exec -it seeg-mongodb mongosh -u admin -p adminpassword seeg_candidatures

# Une fois dans le shell:
db.candidats.find()                           # Voir tous les candidats
db.candidats.countDocuments()                 # Compter
db.candidats.find({first_name: "Sevan"})     # Rechercher
```

#### Statistiques

```bash
# Linux/Mac
./scripts/mongodb_stats.sh

# Windows
.\scripts\mongodb_stats.ps1

# Sortie exemple:
# 📦 Bases de données: seeg_candidatures (2.45 MB)
# 📄 Nombre de candidatures: 15 documents
# 🔍 Index: first_name, last_name, first_name_1_last_name_1
```

#### Backup et Restore

**Backup :**

```bash
# Linux/Mac
./scripts/mongodb_backup.sh

# Windows
.\scripts\mongodb_backup.ps1

# Crée : ./backups/mongodb_YYYYMMDD_HHMMSS/
```

**Restore :**

```bash
# Copier le backup vers le container
docker cp ./backups/mongodb_20250121_143022/seeg_candidatures seeg-mongodb:/tmp/restore

# Restaurer
docker exec seeg-mongodb mongorestore \
  -u admin -p adminpassword \
  --authenticationDatabase admin \
  --db seeg_candidatures \
  /tmp/restore
```

#### Nettoyage

```bash
# Supprimer tous les documents (⚠️ destructif)
./scripts/mongodb_clean.sh

# Ou manuellement
docker exec seeg-mongodb mongosh \
  -u admin -p adminpassword \
  --authenticationDatabase admin \
  seeg_candidatures \
  --eval "db.candidats.deleteMany({})"
```

### Mongo Express (Interface Web)

Interface web pour visualiser et gérer MongoDB :

```
URL: http://localhost:8081
Username: admin
Password: admin
```

**Fonctionnalités :**
- ✅ Visualiser les collections
- ✅ Rechercher dans les documents
- ✅ Créer/Modifier/Supprimer des documents
- ✅ Gérer les index
- ✅ Exporter des données

### Connexion depuis l'application

#### Développement Local (Docker)

```env
MONGODB_CONNECTION_STRING=mongodb://admin:adminpassword@localhost:27017
```

#### Depuis un autre container Docker

```env
# Utiliser le nom du service comme hostname
MONGODB_CONNECTION_STRING=mongodb://admin:adminpassword@mongodb:27017
```

#### MongoDB Compass (GUI externe)

```
mongodb://admin:adminpassword@localhost:27017/?authSource=admin
```

---

## 📝 Utilisation

### Scénario 1 : Traiter des Candidatures

#### 1. Préparer les données

Placer les fichiers JSON des candidats dans le dossier `data/`. Format attendu :

```json
{
  "first_name": "Sevan",
  "last_name": "Kedesh",
  "offre": {
    "intitule": "Développeur Backend Senior",
    "reference": "DEV-2025-001",
    "type_contrat": "CDI",
    "categorie": "Technique",
    ...
  },
  "reponses_mtp": {
    "metier": ["Réponse 1", "Réponse 2", "Réponse 3"],
    ...
  },
  "documents": {
    "cv_url": "https://supabase.../cv.pdf",
    "cover_letter_url": "https://supabase.../lettre.pdf",
    ...
  }
}
```

Exemple complet dans `data/exemple_candidat.json`.

#### 2. Lancer le traitement

```bash
# Activer l'environnement virtuel (si local)
source env/bin/activate  # Linux/Mac
.\env\Scripts\activate   # Windows

# Lancer le script
python main.py
```

**Le script va :**
1. Lire tous les fichiers JSON du dossier `data/`
2. Télécharger les documents depuis Supabase
3. Extraire le texte via OCR Azure
4. Valider les données avec Pydantic
5. Stocker dans MongoDB (upsert = pas de duplication)

#### 3. Vérifier les résultats

```bash
# Via l'API
curl http://localhost:8000/candidatures

# Via MongoDB Shell
docker exec -it seeg-mongodb mongosh -u admin -p adminpassword seeg_candidatures
db.candidats.find().pretty()

# Via Mongo Express
# http://localhost:8081
```

### Scénario 2 : Utiliser l'API

#### Démarrer l'API

```bash
# Avec Docker (recommandé)
docker-compose up -d

# Ou localement
python run_api.py
```

L'API sera accessible sur `http://localhost:8000`

---

## 🌐 API REST

### Documentation Interactive

Une fois l'API démarrée :

- **Swagger UI** : http://localhost:8000/docs
- **ReDoc** : http://localhost:8000/redoc

### Endpoints Disponibles

#### 1. GET `/`

Point d'entrée avec informations sur l'API.

**Requête :**
```bash
curl http://localhost:8000/
```

**Réponse :**
```json
{
  "message": "Bienvenue sur l'API SEEG-AI",
  "version": "1.0.0",
  "endpoints": {
    "candidatures": "/candidatures",
    "search": "/candidatures/search?first_name=XXX&last_name=YYY",
    "health": "/health"
  }
}
```

#### 2. GET `/health`

Vérification de l'état de santé de l'API.

**Requête :**
```bash
curl http://localhost:8000/health
```

**Réponse :**
```json
{
  "status": "healthy",
  "database": "connected"
}
```

#### 3. GET `/candidatures`

Récupère toutes les candidatures.

**Requête :**
```bash
curl http://localhost:8000/candidatures
```

**Réponse :**
```json
[
  {
    "first_name": "Sevan",
    "last_name": "Kedesh",
    "offre": {
      "intitule": "Développeur Backend Senior",
      "reference": "DEV-2025-001",
      "type_contrat": "CDI",
      ...
    },
    "documents": {
      "cv": "Texte extrait du CV par OCR...",
      "cover_letter": "Texte de la lettre...",
      ...
    },
    "reponses_mtp": {
      "metier": ["R1", "R2", "R3"],
      ...
    }
  }
]
```

#### 4. GET `/candidatures/search`

Recherche des candidatures par nom et/ou prénom.

**Paramètres :**
- `first_name` (optionnel) : Prénom à rechercher
- `last_name` (optionnel) : Nom à rechercher

⚠️ Au moins un paramètre est requis.

**Exemples :**

```bash
# Par prénom
curl "http://localhost:8000/candidatures/search?first_name=Sevan"

# Par nom
curl "http://localhost:8000/candidatures/search?last_name=Kedesh"

# Par les deux
curl "http://localhost:8000/candidatures/search?first_name=Sevan&last_name=Kedesh"
```

**Réponse :** Même format que `/candidatures`, filtré selon les critères.

### Schéma de Données

Chaque candidature suit ce schéma JSON :

```json
{
  "first_name": "string",
  "last_name": "string",
  "offre": {
    "intitule": "string",
    "reference": "string",
    "ligne_hierarchique": "string",
    "type_contrat": "CDI|CDD|Stage...",
    "categorie": "Technique|RH|Marketing...",
    "salaire_brut": "string",
    "statut": "Publiée|Fermée...",
    "campagne_recrutement": "string",
    "active": true,
    "date_embauche": "YYYY-MM-DD",
    "lieu_travail": "string",
    "date_limite_candidature": "YYYY-MM-DD",
    "missions_principales": "string",
    "connaissances_requises": "string",
    "questions_mtp": {
      "metier": ["Q1", "Q2", "Q3"],
      "talent": ["Q1", "Q2", "Q3"],
      "paradigme": ["Q1", "Q2", "Q3"]
    },
    "date_publication": "YYYY-MM-DD",
    "autres_informations": "string"
  },
  "reponses_mtp": {
    "metier": ["R1", "R2", "R3"],
    "talent": ["R1", "R2", "R3"],
    "paradigme": ["R1", "R2", "R3"]
  },
  "documents": {
    "cv": "Texte extrait par OCR",
    "cover_letter": "Texte extrait par OCR",
    "diplome": "Texte extrait par OCR",
    "certificats": "Texte extrait par OCR"
  }
}
```

---

## 🐳 Déploiement sur Azure

### Prérequis Azure

- Azure CLI installé : https://docs.microsoft.com/cli/azure/install-azure-cli
- Abonnement Azure actif
- Docker installé localement

### Étape 1 : Connexion à Azure

```bash
# Connexion
az login

# Vérifier votre abonnement
az account show

# Définir l'abonnement (si nécessaire)
az account set --subscription "e44aff73-4ec5-4cf2-ad58-f8b24492970a"

# Créer le resource group
az group create --name seeg-rg --location francecentral
```

### Étape 2 : Azure Document Intelligence

```bash
# Créer la ressource
az cognitiveservices account create \
  --name seeg-document-intelligence \
  --resource-group seeg-rg \
  --kind FormRecognizer \
  --sku S0 \
  --location francecentral \
  --yes

# Récupérer l'endpoint
az cognitiveservices account show \
  --name seeg-document-intelligence \
  --resource-group seeg-rg \
  --query "properties.endpoint" \
  --output tsv

# Récupérer la clé
az cognitiveservices account keys list \
  --name seeg-document-intelligence \
  --resource-group seeg-rg \
  --query "key1" \
  --output tsv
```

### Étape 3 : Azure Cosmos DB (MongoDB API)

```bash
# La base Cosmos DB est déjà créée
# Informations :
# - Nom: seeg-ai
# - API: MongoDB
# - Location: francecentral
# - Admin: Sevan

# Récupérer la chaîne de connexion
az cosmosdb keys list \
  --name seeg-ai \
  --resource-group seeg-rg \
  --type connection-strings
```

### Étape 4 : Azure Container Registry

```bash
ACR_NAME="seegregistry"

# Créer le registry
az acr create \
  --resource-group seeg-rg \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Se connecter au registry
az acr login --name $ACR_NAME
```

### Étape 5 : Build et Push de l'Image Docker

```bash
# Build l'image localement
docker build -t seeg-ai:latest .

# Tag pour Azure Container Registry
docker tag seeg-ai:latest $ACR_NAME.azurecr.io/seeg-ai:latest

# Push vers ACR
docker push $ACR_NAME.azurecr.io/seeg-ai:latest

# Ou build directement dans Azure (plus rapide)
az acr build \
  --registry $ACR_NAME \
  --image seeg-ai:latest \
  --file Dockerfile \
  .
```

### Étape 6 : Déploiement - Option A (Container Instances)

```bash
# Récupérer les credentials ACR
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

# Variables à définir
AZURE_DOC_ENDPOINT="https://seeg-document-intelligence.cognitiveservices.azure.com/"
AZURE_DOC_KEY="votre_cle"
SUPABASE_KEY="votre_cle_supabase"
MONGODB_PASSWORD="votre_password_cosmos"

# Créer le container
az container create \
  --resource-group seeg-rg \
  --name seeg-ai-container \
  --image $ACR_LOGIN_SERVER/seeg-ai:latest \
  --dns-name-label seeg-ai-api \
  --ports 8000 \
  --cpu 1 \
  --memory 2 \
  --environment-variables \
    AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT="$AZURE_DOC_ENDPOINT" \
    AZURE_DOCUMENT_INTELLIGENCE_KEY="$AZURE_DOC_KEY" \
    SUPABASE_URL="https://fyiitzndlqcnyluwkpqp.supabase.co" \
    SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_KEY" \
    MONGODB_CONNECTION_STRING="mongodb+srv://Sevan:$MONGODB_PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000" \
    MONGODB_DATABASE="seeg_candidatures" \
    LOG_LEVEL="INFO" \
  --registry-login-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD

# L'API sera accessible sur :
# http://seeg-ai-api.francecentral.azurecontainer.io:8000
```

### Étape 6 : Déploiement - Option B (App Service)

```bash
# Créer App Service Plan
az appservice plan create \
  --name seeg-app-plan \
  --resource-group seeg-rg \
  --is-linux \
  --sku B1 \
  --location francecentral

# Créer Web App
az webapp create \
  --resource-group seeg-rg \
  --plan seeg-app-plan \
  --name seeg-ai-app \
  --deployment-container-image-name $ACR_LOGIN_SERVER/seeg-ai:latest

# Configurer le registry
az webapp config container set \
  --name seeg-ai-app \
  --resource-group seeg-rg \
  --docker-custom-image-name $ACR_LOGIN_SERVER/seeg-ai:latest \
  --docker-registry-server-url https://$ACR_LOGIN_SERVER \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD

# Configurer les variables d'environnement
az webapp config appsettings set \
  --resource-group seeg-rg \
  --name seeg-ai-app \
  --settings \
    AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT="$AZURE_DOC_ENDPOINT" \
    AZURE_DOCUMENT_INTELLIGENCE_KEY="$AZURE_DOC_KEY" \
    SUPABASE_URL="https://fyiitzndlqcnyluwkpqp.supabase.co" \
    SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_KEY" \
    MONGODB_CONNECTION_STRING="mongodb+srv://Sevan:$MONGODB_PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000" \
    MONGODB_DATABASE="seeg_candidatures" \
    LOG_LEVEL="INFO" \
    WEBSITES_PORT="8000"

# L'API sera accessible sur : https://seeg-ai-app.azurewebsites.net
```

### Étape 7 : Configuration des Secrets (Recommandé)

```bash
# Créer Key Vault
az keyvault create \
  --name seeg-keyvault \
  --resource-group seeg-rg \
  --location francecentral

# Ajouter les secrets
az keyvault secret set \
  --vault-name seeg-keyvault \
  --name "AzureDocumentIntelligenceKey" \
  --value "$AZURE_DOC_KEY"

az keyvault secret set \
  --vault-name seeg-keyvault \
  --name "SupabaseServiceRoleKey" \
  --value "$SUPABASE_KEY"

az keyvault secret set \
  --vault-name seeg-keyvault \
  --name "MongoDBPassword" \
  --value "$MONGODB_PASSWORD"

# Activer l'identité managée pour l'App Service
az webapp identity assign \
  --name seeg-ai-app \
  --resource-group seeg-rg

# Récupérer le principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name seeg-ai-app \
  --resource-group seeg-rg \
  --query principalId \
  --output tsv)

# Donner accès au Key Vault
az keyvault set-policy \
  --name seeg-keyvault \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

### Étape 8 : Monitoring avec Application Insights

```bash
# Créer Application Insights
az monitor app-insights component create \
  --app seeg-app-insights \
  --location francecentral \
  --resource-group seeg-rg

# Récupérer la clé d'instrumentation
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app seeg-app-insights \
  --resource-group seeg-rg \
  --query instrumentationKey \
  --output tsv)

# Ajouter à l'App Service
az webapp config appsettings set \
  --name seeg-ai-app \
  --resource-group seeg-rg \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$INSTRUMENTATION_KEY"
```

### Étape 9 : Vérification

```bash
# Tester l'API
curl https://seeg-ai-app.azurewebsites.net/health

# Voir les logs
az webapp log tail \
  --name seeg-ai-app \
  --resource-group seeg-rg
```

### Mise à jour du Déploiement

```bash
# Rebuild et push
az acr build \
  --registry $ACR_NAME \
  --image seeg-ai:latest \
  --file Dockerfile \
  .

# Redémarrer l'App Service
az webapp restart \
  --name seeg-ai-app \
  --resource-group seeg-rg
```

---

## 🧪 Tests

### Exécuter les Tests

```bash
# Tous les tests
pytest

# Tests avec affichage détaillé
pytest -v

# Tests avec couverture
pytest --cov=src --cov-report=html

# Le rapport sera dans htmlcov/index.html
```

### Tests Spécifiques

```bash
# Tests unitaires des modèles
pytest tests/test_models.py

# Tests API
pytest tests/test_api.py

# Tests processeur
pytest tests/test_processor.py
```

### Structure des Tests

```
tests/
├── __init__.py
├── conftest.py              # Fixtures pytest
├── test_models.py          # Tests unitaires modèles Pydantic
├── test_api.py             # Tests intégration API
└── test_processor.py       # Tests processeur candidatures
```

### Tests Disponibles

**Tests Modèles** (`test_models.py`) :
- Création de candidature valide
- Données minimales
- Valeurs par défaut
- Sérialisation/désérialisation

**Tests API** (`test_api.py`) :
- Root endpoint
- Health check
- Get all candidatures
- Search by first_name
- Search by last_name
- Validation des paramètres
- Gestion des erreurs

**Tests Processeur** (`test_processor.py`) :
- Build candidature from JSON
- Données minimales
- Clés alternatives
- Process documents

---

## 🛠️ Scripts Utilitaires

### Scripts de Setup

```bash
# Linux/Mac
chmod +x scripts/setup_env.sh
./scripts/setup_env.sh

# Windows
.\scripts\setup_env.ps1
```

**Fonctionnalités :**
- Création environnement virtuel
- Installation des dépendances
- Création des dossiers
- Vérification de la configuration

### Scripts MongoDB

#### Linux/Mac (Bash)

```bash
# Accéder au shell MongoDB
./scripts/mongodb_cli.sh

# Voir les statistiques
./scripts/mongodb_stats.sh

# Faire un backup
./scripts/mongodb_backup.sh

# Nettoyer la base
./scripts/mongodb_clean.sh
```

#### Windows (PowerShell)

```powershell
# Voir les statistiques
.\scripts\mongodb_stats.ps1

# Faire un backup
.\scripts\mongodb_backup.ps1
```

### Script de Test API

```bash
# Tester l'API localement
chmod +x scripts/test_api.sh
./scripts/test_api.sh

# Tester une API distante
./scripts/test_api.sh https://seeg-ai-app.azurewebsites.net
```

### Script de Vérification

```bash
# Vérifier que tout est bien configuré
python scripts/check_setup.py
```

**Vérifie :**
- Version Python
- Fichier .env
- Variables d'environnement
- Dépendances installées
- Dossiers présents
- Docker installé
- Fichiers de données

### Makefile (Commandes Simplifiées)

```bash
# Voir toutes les commandes
make help

# Installation
make install

# Tests
make test
make test-cov

# Lancer l'API
make run-api

# Traiter les candidatures
make run-processor

# Docker
make docker-build
make docker-up
make docker-down
make docker-logs

# Nettoyage
make clean

# Formatage code
make format
make lint
```

---

## 🔧 Dépannage

### Problèmes Courants

#### 1. L'API ne démarre pas

**Symptômes :** Erreur au lancement de `python run_api.py` ou `docker-compose up`

**Solutions :**

```bash
# Vérifier que MongoDB tourne
docker-compose ps mongodb

# Voir les logs
docker-compose logs mongodb

# Redémarrer MongoDB
docker-compose restart mongodb

# Vérifier le fichier .env
cat .env  # Linux/Mac
type .env  # Windows

# Tester la connexion MongoDB
docker exec seeg-mongodb mongosh -u admin -p adminpassword --eval "db.adminCommand('ping')"
```

#### 2. Erreur de connexion Azure

**Symptômes :** Erreur lors de l'extraction OCR

**Solutions :**

```bash
# Vérifier les variables Azure
echo $AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT
echo $AZURE_DOCUMENT_INTELLIGENCE_KEY

# Tester manuellement
python -c "from src.config import settings; print(settings.azure_document_intelligence_endpoint)"

# Vérifier que la ressource existe sur Azure
az cognitiveservices account show \
  --name seeg-document-intelligence \
  --resource-group seeg-rg
```

#### 3. Erreur MongoDB

**Symptômes :** Cannot connect to MongoDB

**Solutions :**

```bash
# Vérifier que le container tourne
docker ps | grep seeg-mongodb

# Vérifier le port
netstat -ano | findstr :27017  # Windows
lsof -i :27017                 # Linux/Mac

# Recréer le container
docker-compose down
docker-compose up -d mongodb

# Vérifier les logs
docker-compose logs -f mongodb
```

#### 4. Aucune candidature dans la base

**Symptômes :** API retourne une liste vide

**Solutions :**

```bash
# Vérifier qu'il y a des fichiers JSON
ls data/  # Linux/Mac
dir data  # Windows

# Lancer le traitement
python main.py

# Vérifier dans MongoDB
docker exec -it seeg-mongodb mongosh \
  -u admin -p adminpassword \
  seeg_candidatures \
  --eval "db.candidats.countDocuments()"

# Via Mongo Express
# http://localhost:8081
```

#### 5. Le port 8000 est déjà utilisé

**Symptômes :** Address already in use

**Solutions :**

```bash
# Trouver le processus qui utilise le port
netstat -ano | findstr :8000  # Windows
lsof -i :8000                 # Linux/Mac

# Tuer le processus (remplacer PID)
kill -9 PID  # Linux/Mac
taskkill /PID PID /F  # Windows

# Ou changer le port dans .env
API_PORT=8001
```

#### 6. Erreurs de dépendances Python

**Symptômes :** ImportError, ModuleNotFoundError

**Solutions :**

```bash
# Réinstaller les dépendances
pip install --upgrade pip
pip install -r requirements.txt

# Vérifier l'environnement virtuel
which python  # Linux/Mac
where python  # Windows

# Activer l'environnement
source env/bin/activate  # Linux/Mac
.\env\Scripts\activate   # Windows
```

### Logs et Debugging

#### Voir les logs de l'application

```bash
# Logs fichiers
tail -f logs/seeg-ai_*.log  # Linux/Mac
Get-Content logs/seeg-ai_*.log -Wait  # Windows

# Logs Docker
docker-compose logs -f seeg-api
docker-compose logs -f mongodb
```

#### Activer le mode debug

```env
# Dans .env
LOG_LEVEL=DEBUG
```

#### Vérifier la configuration

```bash
# Script de vérification
python scripts/check_setup.py

# Vérifier les variables
python -c "from src.config import settings; print(settings.model_dump())"
```

### Réinitialisation Complète

Si rien ne fonctionne, réinitialiser complètement :

```bash
# 1. Arrêter et supprimer tout
docker-compose down -v

# 2. Supprimer l'environnement virtuel
rm -rf env  # Linux/Mac
rmdir /s env  # Windows

# 3. Nettoyer les fichiers temporaires
make clean
# ou
rm -rf temp/* logs/* __pycache__

# 4. Recréer l'environnement
python -m venv env
source env/bin/activate  # Linux/Mac
.\env\Scripts\activate   # Windows

# 5. Réinstaller
pip install -r requirements.txt

# 6. Redémarrer Docker
docker-compose up -d
```

---

## 🏛️ Architecture Technique Détaillée

### Couches de l'Application

```
┌─────────────────────────────────────────────────────────┐
│                  COUCHE PRÉSENTATION                     │
│  ┌──────────────────────────────────────────────────┐  │
│  │  FastAPI (src/api/app.py)                        │  │
│  │  - Routes REST                                    │  │
│  │  - Validation requêtes                           │  │
│  │  - Sérialisation réponses                        │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────┐
│                  COUCHE MÉTIER                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │  CandidatureProcessor (src/processor/)           │  │
│  │  - Orchestration du traitement                   │  │
│  │  - Logique de transformation                     │  │
│  │  - Validation métier                             │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────┐
│                  COUCHE SERVICES                         │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Azure OCR  │  │  Supabase    │  │  MongoDB     │  │
│  │  Service    │  │  Client      │  │  Client      │  │
│  └─────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Patterns Utilisés

#### 1. Singleton Pattern

Chaque client (MongoDB, Azure, Supabase) est une instance globale unique :

```python
# src/database/mongodb_client.py
mongodb_client = MongoDBClient()

# Utilisé partout
from src.database import mongodb_client
mongodb_client.connect()
```

#### 2. Dependency Injection

Configuration injectée via Pydantic Settings :

```python
# src/config.py
class Settings(BaseSettings):
    azure_document_intelligence_endpoint: str
    # ...

settings = Settings()  # Charge depuis .env
```

#### 3. Repository Pattern

MongoDB Client encapsule toutes les opérations DB :

```python
class MongoDBClient:
    def get_all_candidatures(self) -> List[Dict]
    def search_candidatures(...) -> List[Dict]
    def insert_or_update_candidature(...) -> str
```

#### 4. Validation Layer

Pydantic pour la validation automatique :

```python
class Candidature(BaseModel):
    first_name: Optional[str]
    last_name: Optional[str]
    offre: Offre
    documents: Documents
```

### Technologies Utilisées

| Catégorie | Technologie | Version |
|-----------|-------------|---------|
| **Backend** | Python | 3.11+ |
| **Framework API** | FastAPI | 0.109.0 |
| **Validation** | Pydantic | 2.5.3 |
| **OCR** | Azure Document Intelligence | 1.0.0b1 |
| **Base de données** | MongoDB / Azure Cosmos DB | 7.0 / 8.0 |
| **Storage** | Supabase | 2.3.4 |
| **HTTP Client** | httpx, aiohttp | - |
| **Logging** | Loguru | 0.7.2 |
| **Tests** | Pytest | 7.4.4 |
| **Containerisation** | Docker | - |
| **Cloud** | Azure | - |

### Sécurité

#### Layers de Sécurité

```
1. Secrets Management
   └─► Variables d'environnement (.env)
       └─► Azure Key Vault (production)

2. Network Security
   └─► TLS/SSL pour toutes les connexions
       ├─► Azure services (HTTPS)
       ├─► Cosmos DB (mongodb+srv://)
       └─► Supabase (HTTPS)

3. Authentication
   └─► Service Role Keys (Supabase)
       └─► API Keys (Azure)
           └─► Credentials (MongoDB)

4. API Security
   └─► CORS configuré
       └─► Input validation (Pydantic)
           └─► Rate limiting (à implémenter)
```

### Scalabilité

#### Stratégies de Scale

1. **Horizontal Scaling**
   - API : Multiple instances (Azure App Service)
   - Processing : Workers parallèles

2. **Vertical Scaling**
   - Cosmos DB : Throughput ajustable
   - Container Instances : CPU/Memory configurables

3. **Caching** (à implémenter)
   - Redis pour les résultats de recherche

4. **Async Processing**
   - Queue-based pour traitement batch

### Monitoring et Observabilité

**Application Insights** :
- Métriques applicatives
- Temps de réponse
- Taux d'erreur

**Azure Monitor** :
- Métriques infrastructure
- CPU, Memory, Network

**Loguru** :
- Logs structurés
- Rotation automatique
- Niveaux configurables

**Cosmos DB Metrics** :
- Request Units (RU)
- Performance DB

---

## 🤝 Contribution

### Comment Contribuer

1. **Fork et Clone**

```bash
git clone https://github.com/votre-username/SEEG-AI.git
cd SEEG-AI
```

2. **Créer une Branche**

```bash
git checkout -b feat/ma-nouvelle-fonctionnalite
```

3. **Développer et Tester**

```bash
# Développez votre fonctionnalité

# Testez
pytest

# Formatez le code
black src/
flake8 src/
```

4. **Commit**

```bash
git add .
git commit -m "feat: Description de ma fonctionnalité"
```

**Convention de commit :**
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `test`: Tests
- `refactor`: Refactoring
- `chore`: Maintenance

5. **Push et Pull Request**

```bash
git push origin feat/ma-nouvelle-fonctionnalite
```

Créez une PR sur GitHub avec :
- Titre clair
- Description détaillée
- Tests ajoutés
- Documentation mise à jour

### Standards de Code

**Style Python** : PEP 8

```python
# Imports groupés
import standard_library
import third_party
from src import local_imports

# Docstrings en français
def ma_fonction(param: str) -> bool:
    """
    Description de la fonction
    
    Args:
        param: Description du paramètre
        
    Returns:
        Description du retour
    """
    pass

# Type hints obligatoires
def process_data(data: Dict[str, Any]) -> List[str]:
    pass
```

**Formatage** :
- `black src/` pour le formatage
- `flake8 src/` pour le linting
- `mypy src/` pour le type checking

### Tests

Écrire des tests pour toute nouvelle fonctionnalité :

```python
# tests/test_mon_module.py
import pytest
from src.mon_module import ma_fonction

def test_ma_fonction():
    """Test de ma_fonction avec cas nominal"""
    result = ma_fonction("input")
    assert result == "expected_output"
```

### Checklist avant PR

- [ ] Code formaté avec Black
- [ ] Pas d'erreur Flake8
- [ ] Type hints ajoutés
- [ ] Tests écrits et passants
- [ ] Documentation mise à jour
- [ ] Pas de credentials dans le code
- [ ] Logs appropriés ajoutés

---

## 📚 Ressources

### Documentation

- [FastAPI](https://fastapi.tiangolo.com/)
- [Pydantic](https://docs.pydantic.dev/)
- [Azure Document Intelligence](https://docs.microsoft.com/azure/cognitive-services/form-recognizer/)
- [MongoDB](https://docs.mongodb.com/)
- [Docker](https://docs.docker.com/)
- [Azure Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/)

### Support

- **Logs** : Consultez `logs/`
- **Health Check** : http://localhost:8000/health
- **Documentation API** : http://localhost:8000/docs
- **Tests** : `pytest` command

---

## 📄 Licence

Propriété de SEEG - Tous droits réservés

---

## 📞 Contact

**Créé par l'équipe SEEG-AI** | Version 1.0.0 | 2025

---

**Prêt à démarrer ? Lancez `docker-compose up -d` ! 🚀**
