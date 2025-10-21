# 🏗️ Architecture SEEG-AI - Développement & Production

## 📊 Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                    SEEG-AI - SYSTÈME COMPLET                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐         ┌─────────────────────────┐
│   DÉVELOPPEMENT LOCAL   │         │  PRODUCTION AZURE       │
│                         │         │                         │
│  ┌──────────────────┐  │         │  ┌──────────────────┐  │
│  │  Python Scripts  │  │         │  │   App Service    │  │
│  │  - main.py       │  │         │  │  (Web App)       │  │
│  │  - run_api.py    │  │         │  │                  │  │
│  └──────────────────┘  │         │  │  FastAPI         │  │
│         ↓               │         │  │  Docker Image    │  │
│  ┌──────────────────┐  │         │  └──────────────────┘  │
│  │  MongoDB         │  │         │         ↓               │
│  │  (Docker)        │  │   →→→→→ │  ┌──────────────────┐  │
│  └──────────────────┘  │         │  │  Cosmos DB       │  │
│         ↓               │         │  │  (MongoDB API)   │  │
│  ┌──────────────────┐  │         │  └──────────────────┘  │
│  │  Mongo Express   │  │         │                         │
│  │  localhost:8081  │  │         │  ┌──────────────────┐  │
│  └──────────────────┘  │         │  │  App Insights    │  │
│                         │         │  │  (Monitoring)    │  │
└─────────────────────────┘         └─────────────────────────┘

         ↓                                    ↓
┌─────────────────────────────────────────────────────────────────┐
│                     SERVICES PARTAGÉS                           │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │  Supabase        │  │  Azure OCR       │  │  Azure CLI   │ │
│  │  (Fichiers)      │  │  (Document Intel)│  │  (Gestion)   │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flux de Données - Traitement des Candidatures

```
1. LECTURE JSON
   ↓
   data/Donnees_candidatures_SEEG.json
   (182 candidats)

2. TÉLÉCHARGEMENT DOCUMENTS
   ↓
   Supabase Storage
   → https://fyiitzndlqcnyluwkpqp.supabase.co/storage/v1/object/public/application-documents/
   → CV, Lettre, Diplôme, Certificats

3. EXTRACTION OCR
   ↓
   Azure Document Intelligence
   → https://seeg-document-intelligence.cognitiveservices.azure.com/
   → Texte structuré extrait

4. TRANSFORMATION
   ↓
   Python Pydantic Models
   → Validation et normalisation
   → ID unique généré

5. SAUVEGARDE
   ↓
   MongoDB / Cosmos DB
   → Base: SEEG-AI
   → Collection: candidats
   → ID: ObjectId unique

6. EXPOSITION API
   ↓
   FastAPI REST API
   → GET /candidatures
   → GET /candidatures/search
```

---

## 🗄️ Structure MongoDB

```javascript
{
  "_id": ObjectId("68f77d46cd6ed5c7ea2e64f8"),
  "application_id": "dcb5fdca-fd83-44cc-b0c2-6593c85ccf39",  // UUID unique
  "first_name": "Eric Hervé",
  "last_name": "EYOGO TOUNG",
  "email": "meejetjunior@gmail.com",
  "date_candidature": "2024-10-13T17:52:37.938Z",
  
  "offre": {
    "intitule": "Directeur Juridique, Communication & RSE",
    "reference": "beb41aa7-7c7a-4aec-8b15-c5e93dcb4d05",
    "type_contrat": "CDI",
    "categorie": "Cadre dirigeant",
    "questions_mtp": {
      "metier": [...],
      "talent": [...],
      "paradigme": [...]
    }
  },
  
  "reponses_mtp": {
    "metier": [...],
    "talent": [...],
    "paradigme": [...]
  },
  
  "documents": {
    "cv": "M. Eric-Hervé EYOGO-TOUNG... (9438 caractères)",
    "lettre_motivation": "Libreville, le 12 octobre 2024... (2834 caractères)",
    "diplome": "UNIVERSITÉ SORBONNE... (10717 caractères)",
    "certificats": "RÉPUBLIQUE GABONAISE... (6832 caractères)"
  },
  
  "statut": "en_attente",
  "date_creation": "2025-10-21T13:32:06.123Z",
  "date_mise_a_jour": "2025-10-21T13:32:06.123Z"
}
```

---

## 🌐 API REST - Endpoints

### 1. Route Racine

```http
GET /
```

**Réponse** :
```json
{
  "message": "API SEEG Candidatures",
  "version": "1.0.0",
  "endpoints": {
    "health": "/health",
    "candidatures": "/candidatures",
    "search": "/candidatures/search",
    "docs": "/docs"
  }
}
```

---

### 2. Health Check

```http
GET /health
```

**Réponse** :
```json
{
  "status": "healthy",
  "database": "connected"
}
```

---

### 3. Liste Complète

```http
GET /candidatures
```

**Réponse** :
```json
[
  {
    "application_id": "dcb5fdca-fd83-44cc-b0c2-6593c85ccf39",
    "first_name": "Eric Hervé",
    "last_name": "EYOGO TOUNG",
    "email": "meejetjunior@gmail.com",
    "offre": {...},
    "documents": {...}
  },
  ...
]
```

---

### 4. Recherche

```http
GET /candidatures/search?first_name=Eric
GET /candidatures/search?last_name=EYOGO
GET /candidatures/search?email=meejetjunior@gmail.com
```

**Réponse** :
```json
[
  {
    "application_id": "dcb5fdca-fd83-44cc-b0c2-6593c85ccf39",
    "first_name": "Eric Hervé",
    "last_name": "EYOGO TOUNG",
    ...
  }
]
```

---

## 🐳 Architecture Docker

### docker-compose.yml

```yaml
services:
  mongodb:
    image: mongo:7.0
    environment:
      MONGO_INITDB_ROOT_USERNAME: Sevan
      MONGO_INITDB_ROOT_PASSWORD: SevanSeeg2025
      MONGO_INITDB_DATABASE: SEEG-AI
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
  
  mongo-express:
    image: mongo-express:latest
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: Sevan
      ME_CONFIG_MONGODB_ADMINPASSWORD: SevanSeeg2025
      ME_CONFIG_MONGODB_URL: mongodb://Sevan:SevanSeeg2025@mongodb:27017/
  
  seeg-api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=...
      - MONGODB_CONNECTION_STRING=...
      - SUPABASE_URL=...
    depends_on:
      - mongodb
```

---

## 🚀 Déploiement Azure - Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     RESOURCE GROUP: seeg-rg                 │
│                   Location: francecentral                   │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│  Container Registry  │
│  seegregistry.azurecr.io
│                      │
│  Images:             │
│  - seeg-api:latest   │
└──────────────────────┘
         ↓
┌──────────────────────┐
│  App Service Plan    │
│  seeg-app-plan       │
│  SKU: B1 (Linux)     │
└──────────────────────┘
         ↓
┌──────────────────────┐
│  Web App             │
│  seeg-ai-api         │
│                      │
│  URL:                │
│  seeg-ai-api.        │
│  azurewebsites.net   │
│                      │
│  Container:          │
│  seegregistry.azurecr│
│  .io/seeg-api:latest │
└──────────────────────┘
         ↓
┌──────────────────────┐
│  Cosmos DB           │
│  seeg-ai             │
│  API: MongoDB        │
│                      │
│  Database: SEEG-AI   │
│  Collection:         │
│  - candidats         │
└──────────────────────┘

┌──────────────────────┐
│  Document Intel      │
│  seeg-document-      │
│  intelligence        │
│                      │
│  API: Form Recognizer│
│  Model: prebuilt-read│
└──────────────────────┘

┌──────────────────────┐
│  App Insights        │
│  seeg-app-insights   │
│  (Optionnel)         │
└──────────────────────┘

┌──────────────────────┐
│  Key Vault           │
│  seeg-keyvault       │
│  (Recommandé)        │
│                      │
│  Secrets:            │
│  - CosmosDB Pass     │
│  - OCR Key           │
│  - Supabase Key      │
└──────────────────────┘
```

---

## 📦 Structure du Projet

```
SEEG-AI/
│
├── src/
│   ├── __init__.py
│   ├── config.py                    # Configuration centralisée
│   ├── logger.py                    # Logging unifié
│   ├── models.py                    # Modèles Pydantic
│   │
│   ├── database/
│   │   ├── __init__.py
│   │   └── mongodb_client.py        # Client MongoDB
│   │
│   ├── services/
│   │   ├── __init__.py
│   │   ├── supabase_client.py       # Téléchargement fichiers
│   │   └── azure_ocr.py             # Extraction OCR
│   │
│   ├── processor/
│   │   ├── __init__.py
│   │   └── candidature_processor.py # Orchestration
│   │
│   └── api/
│       ├── __init__.py
│       └── app.py                   # FastAPI endpoints
│
├── data/
│   └── Donnees_candidatures_SEEG.json  # 182 candidats
│
├── scripts/
│   ├── mongodb_backup.ps1
│   ├── mongodb_stats.ps1
│   └── mongodb_cli.sh
│
├── tests/
│   ├── __init__.py
│   ├── test_models.py
│   ├── test_mongodb.py
│   ├── test_ocr.py
│   └── test_api.py
│
├── main.py                         # Traitement des candidatures
├── run_api.py                      # Lancement API
├── test_one_candidate.py           # Test unitaire
│
├── Dockerfile                      # Image Docker
├── docker-compose.yml              # Orchestration locale
├── requirements.txt                # Dépendances Python
│
├── deploy_azure.ps1                # Script déploiement
├── .env                            # Variables locales (gitignored)
├── env.production.seeg             # Template production
│
├── README.md                       # Documentation principale
├── DEPLOIEMENT_AZURE_COMPLET.md   # Guide déploiement détaillé
├── PRET_POUR_AZURE.md             # Checklist déploiement
└── ARCHITECTURE_DEPLOIEMENT.md    # Ce fichier
```

---

## 🔐 Variables d'Environnement

### Développement Local (.env)

```env
# Azure OCR
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://seeg-document-intelligence.cognitiveservices.azure.com/
AZURE_DOCUMENT_INTELLIGENCE_KEY=c692c5eb3c8c4f269af44c16ec339a7a

# Supabase
SUPABASE_URL=https://fyiitzndlqcnyluwkpqp.supabase.co
SUPABASE_BUCKET_NAME=application-documents

# MongoDB Local
MONGODB_CONNECTION_STRING=mongodb://Sevan:SevanSeeg2025@localhost:27017
MONGODB_DATABASE=SEEG-AI
MONGODB_COLLECTION=candidats
```

### Production Azure

```env
# Identiques sauf MongoDB
MONGODB_CONNECTION_STRING=mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256
```

---

## ⚡ Performance & Limites

### Azure Document Intelligence

```
Modèle: prebuilt-read
Limite: 15 appels/seconde
Prix: ~1€ pour 1000 pages

Pour 182 candidats × 4 documents = 728 documents
Coût estimé: ~0.73€
Temps: ~2-3 minutes
```

### Cosmos DB

```
Niveau: Serverless (recommandé pour démarrer)
RU/s: Auto-scaling
Stockage: 182 documents ≈ 5-10 MB
Coût estimé: ~0.25€/jour avec peu de requêtes
```

### App Service

```
SKU: B1 Basic
vCPU: 1
RAM: 1.75 GB
Coût: ~13€/mois
```

**Coût total estimé** : ~15€/mois + consommation OCR ponctuelle

---

## 🎯 Commandes Essentielles

### Développement Local

```powershell
# Setup
.\env\Scripts\Activate.ps1
pip install -r requirements.txt

# Lancer MongoDB
docker-compose up -d mongodb mongo-express

# Traiter les candidats
python main.py

# API locale
python run_api.py
curl http://localhost:8000/health

# Tests
python test_one_candidate.py
pytest
```

### Production Azure

```powershell
# Déploiement
.\deploy_azure.ps1

# Logs
az webapp log tail --name seeg-ai-api --resource-group seeg-rg

# Statut
az webapp show --name seeg-ai-api --resource-group seeg-rg

# Test
curl https://seeg-ai-api.azurewebsites.net/health
```

---

## ✅ Points Clés

1. **ID Unique** : `application_id` (UUID) pour chaque candidat
2. **Idempotence** : Upsert basé sur `application_id`
3. **OCR Robuste** : Retry automatique, gestion erreurs
4. **API RESTful** : FastAPI avec validation Pydantic
5. **Dockerisé** : Prêt pour dev et prod
6. **Azure Native** : Cosmos DB + Document Intelligence + App Service
7. **Monitoring** : Logs structurés + Application Insights (optionnel)
8. **Sécurité** : Key Vault + Managed Identity (recommandé)

---

## 🚀 Prochaines Étapes

1. ✅ Système testé localement
2. 🔄 **Déployer sur Azure** → `.\deploy_azure.ps1`
3. 🔄 **Migrer les données** → Export/Import vers Cosmos DB
4. 🔄 **Tester en production** → `curl https://seeg-ai-api.azurewebsites.net/health`
5. 📊 **Monitoring** → Application Insights
6. 🔒 **Sécurité** → Key Vault pour les secrets
7. 🎨 **Frontend** → Interface web (futur)

---

Vous êtes prêt ! 🎉

