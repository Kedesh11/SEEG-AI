# SEEG-AI - Système de Traitement Automatisé de Candidatures

[![Status](https://img.shields.io/badge/Status-Production%20Ready-success)](https://seeg-ai-api.azurewebsites.net)
[![API](https://img.shields.io/badge/API-Online-blue)](https://seeg-ai-api.azurewebsites.net/docs)
[![Python](https://img.shields.io/badge/Python-3.13-blue)](https://www.python.org/)
[![Azure](https://img.shields.io/badge/Azure-Deployed-0078D4)](https://portal.azure.com)

> **✅ Déploiement Azure Réussi** - API accessible sur https://seeg-ai-api.azurewebsites.net

---

## 📋 Table des Matières

1. [Description](#-description)
2. [Démarrage Rapide](#-démarrage-rapide-local)
3. [API Déployée (Azure)](#-api-déployée-sur-azure)
4. [Architecture](#-architecture)
5. [Installation Locale](#-installation-locale-complète)
6. [Configuration](#-configuration)
7. [Utilisation](#-utilisation)
8. [API REST](#-api-rest)
9. [Déploiement Azure](#-déploiement-sur-azure)
10. [Tests](#-tests)
11. [Scripts Utilitaires](#-scripts-utilitaires)
12. [Dépannage](#-dépannage)

---

## 📋 Description

SEEG-AI est une solution complète de traitement automatisé de candidatures pour la SEEG (Société d'Énergie et d'Eau du Gabon).

### ✨ Fonctionnalités

- 📄 **Extraction OCR** via Azure Document Intelligence (prebuilt-read)
- 💾 **Stockage MongoDB/Cosmos DB** avec schéma structuré
- 🌐 **API REST FastAPI** avec 4 endpoints publics
- 🔄 **Traitement idempotent** (pas de duplication)
- 🐳 **Architecture Docker** pour développement et production
- 📊 **Interface Mongo Express** pour visualiser les données
- 📚 **Documentation Swagger** interactive
- ☁️ **Déployé sur Azure** et opérationnel

### 🎯 Workflow

```
1. Lecture JSON → 2. Téléchargement Supabase → 3. OCR Azure → 4. Sauvegarde MongoDB → 5. API REST
```

---

## 🚀 Démarrage Rapide (Local)

### Prérequis

- Python 3.13
- Docker Desktop
- Azure CLI (pour déploiement)

### En 3 Minutes

```powershell
# 1. Cloner et configurer
git clone <repo>
cd SEEG-AI

# 2. Créer .env (copier depuis env.production.seeg)
copy env.production.seeg .env

# 3. Activer environnement virtuel
.\env\Scripts\Activate.ps1
pip install -r requirements.txt

# 4. Lancer MongoDB
docker-compose up -d mongodb mongo-express

# 5. Tester un candidat
python test_one_candidate.py

# 6. Lancer l'API
python run_api.py
```

**L'API locale sera sur** : http://localhost:8000

---

## ☁️ API Déployée sur Azure

### 🌐 URLs de Production

| Service | URL |
|---------|-----|
| **API Base** | https://seeg-ai-api.azurewebsites.net |
| **Health Check** | https://seeg-ai-api.azurewebsites.net/health |
| **Documentation** | https://seeg-ai-api.azurewebsites.net/docs |
| **Candidatures** | https://seeg-ai-api.azurewebsites.net/candidatures |
| **Recherche** | https://seeg-ai-api.azurewebsites.net/candidatures/search |

### 📊 Statistiques

```
✅ Status:              Healthy
✅ Database:            Connected (Cosmos DB)
✅ Candidatures:        183 documents
✅ Dernière MAJ:        21 octobre 2025
```

### 🧪 Tester l'API

```powershell
# Health check
curl https://seeg-ai-api.azurewebsites.net/health

# Liste des candidatures
curl https://seeg-ai-api.azurewebsites.net/candidatures

# Recherche
curl "https://seeg-ai-api.azurewebsites.net/candidatures/search?last_name=NDZANGA"

# Documentation interactive
Start-Process "https://seeg-ai-api.azurewebsites.net/docs"
```

### 🔐 Ressources Azure

| Ressource | Nom | Détails |
|-----------|-----|---------|
| **Cosmos DB** | seeg-ai | MongoDB API, France Central |
| **App Service** | seeg-ai-api | B1 Basic (1 vCPU, 1.75 GB) |
| **Container Registry** | seegregistry | Image: seeg-api:latest |
| **Document Intelligence** | seeg-document-intelligence | Form Recognizer API |

---

## 🏗️ Architecture

### Vue d'Ensemble

```
┌─────────────────────────────────────────────────────┐
│                   AZURE CLOUD                       │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  App Service (seeg-ai-api)                   │  │
│  │  https://seeg-ai-api.azurewebsites.net       │  │
│  └──────────────────────────────────────────────┘  │
│                      ↓                              │
│  ┌──────────────────────────────────────────────┐  │
│  │  Cosmos DB (MongoDB API)                     │  │
│  │  183 candidatures                            │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Document Intelligence (OCR)                 │  │
│  │  Extraction texte des PDF                    │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
         ↓                              ↑
    HTTP/HTTPS                    Supabase Storage
         ↓                              ↑
   [Utilisateurs]              [Documents PDF]
```

### Technologies

- **Backend** : Python 3.13, FastAPI, Uvicorn
- **Base de données** : MongoDB 7.0 / Azure Cosmos DB
- **OCR** : Azure Form Recognizer (prebuilt-read)
- **Stockage** : Supabase Storage
- **Containerisation** : Docker, Docker Compose
- **Cloud** : Microsoft Azure
- **API** : REST, OpenAPI 3.0

---

## 💻 Installation Locale Complète

### 1. Prérequis

```bash
# Vérifier Python
python --version  # Doit être 3.13

# Vérifier Docker
docker --version
docker ps

# Vérifier Azure CLI (pour déploiement)
az --version
```

### 2. Installation des Dépendances

```powershell
# Créer environnement virtuel
python -m venv env

# Activer
.\env\Scripts\Activate.ps1  # Windows
source env/bin/activate      # Linux/Mac

# Installer dépendances
pip install -r requirements.txt
```

### 3. Lancer MongoDB

```powershell
# Démarrer tous les services
docker-compose up -d

# Vérifier
docker ps
```

**Services disponibles** :
- MongoDB : `localhost:27017`
- Mongo Express : http://localhost:8081
- Credentials : `Sevan` / `SevanSeeg2025`

---

## ⚙️ Configuration

### Fichier `.env`

Créer `.env` à la racine (copier depuis `env.production.seeg`) :

```env
# Azure Document Intelligence
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://seeg-document-intelligence.cognitiveservices.azure.com/
AZURE_DOCUMENT_INTELLIGENCE_KEY=c692c5eb3c8c4f269af44c16ec339a7a

# Supabase
SUPABASE_URL=https://fyiitzndlqcnyluwkpqp.supabase.co
SUPABASE_BUCKET_NAME=application-documents
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# MongoDB Local (pour développement)
MONGODB_CONNECTION_STRING=mongodb://Sevan:SevanSeeg2025@localhost:27017
MONGODB_DATABASE=SEEG-AI
MONGODB_COLLECTION=candidats

# Pour utiliser Cosmos DB (production)
# MONGODB_CONNECTION_STRING=mongodb://seeg-ai:***@seeg-ai.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb

# Application
LOG_LEVEL=INFO
```

### Récupérer les Credentials Azure

```bash
# Connection string Cosmos DB
az cosmosdb keys list --name seeg-ai --resource-group seeg-rg --type connection-strings

# Clés Document Intelligence
az cognitiveservices account keys list --name seeg-document-intelligence --resource-group seeg-rg
```

---

## 🎯 Utilisation

### 1. Traiter les Candidatures

#### Test avec un seul candidat

```powershell
python test_one_candidate.py
```

**Résultat attendu** :
```
✅ Candidat traité: Eric Hervé EYOGO TOUNG
✅ 4 documents téléchargés et OCRisés
✅ Sauvegardé dans MongoDB
```

#### Traiter tous les candidats

```powershell
python main.py
```

**Ce qui se passe** :
1. Lecture de `data/Donnees_candidatures_SEEG.json` (183 candidats)
2. Pour chaque candidat :
   - Téléchargement des documents depuis Supabase
   - Extraction OCR via Azure
   - Sauvegarde dans MongoDB avec ID unique
3. Rapport final avec statistiques

### 2. Lancer l'API

```powershell
python run_api.py
```

**API disponible sur** : http://localhost:8000

### 3. Accéder à la Documentation

- **Swagger UI** : http://localhost:8000/docs
- **ReDoc** : http://localhost:8000/redoc
- **Mongo Express** : http://localhost:8081

---

## 🌐 API REST

### Endpoints

#### 1. Health Check

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

#### 2. Info API

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

#### 3. Liste des Candidatures

```http
GET /candidatures
```

**Réponse** : Array de candidatures

**Exemple** :
```json
[
  {
    "application_id": "dcb5fdca-fd83-44cc-b0c2-6593c85ccf39",
    "first_name": "Eric Hervé",
    "last_name": "EYOGO TOUNG",
    "email": "meejetjunior@gmail.com",
    "date_candidature": "2024-10-13T17:52:37.938Z",
    "offre": {
      "intitule": "Directeur Juridique, Communication & RSE",
      "reference": "beb41aa7-7c7a-4aec-8b15-c5e93dcb4d05",
      "type_contrat": "CDI",
      "categorie": "Cadre dirigeant"
    },
    "documents": {
      "cv": "M. Eric-Hervé EYOGO-TOUNG... (9438 caractères)",
      "lettre_motivation": "Libreville, le 12 octobre 2024...",
      "diplome": "...",
      "certificats": "..."
    },
    "reponses_mtp": {
      "metier": [...],
      "talent": [...],
      "paradigme": [...]
    },
    "statut": "en_attente"
  }
]
```

---

#### 4. Recherche

```http
GET /candidatures/search?first_name={prenom}
GET /candidatures/search?last_name={nom}
GET /candidatures/search?email={email}
```

**Paramètres** : Au moins un requis

**Exemples** :
```bash
# Recherche par nom
curl "http://localhost:8000/candidatures/search?last_name=NDZANGA"

# Recherche par prénom
curl "http://localhost:8000/candidatures/search?first_name=Eric"

# Recherche combinée
curl "http://localhost:8000/candidatures/search?first_name=Eric&last_name=EYOGO"
```

---

## ☁️ Déploiement sur Azure

### Déploiement Automatique

Le système est déjà déployé et opérationnel. Pour redéployer ou mettre à jour :

```powershell
# Déploiement complet
.\deploy_azure.ps1

# Options disponibles
.\deploy_azure.ps1 -SkipBuild              # Sans rebuild Docker
.\deploy_azure.ps1 -OnlyConfig             # Config uniquement
.\deploy_azure.ps1 -SkipDataMigration      # Sans migration données
.\deploy_azure.ps1 -SkipTests              # Sans tests
```

**Le script effectue** :
1. ✅ Vérification connexion Azure
2. ✅ Récupération credentials Cosmos DB
3. ✅ Build et push image Docker vers ACR
4. ✅ Création/mise à jour App Service
5. ✅ Configuration variables d'environnement
6. ✅ Migration optionnelle des données
7. ✅ Tests automatiques
8. ✅ Rapport final

**Durée** : 10-15 minutes

### Ressources Créées

```
✅ Cosmos DB:            seeg-ai (MongoDB API)
✅ Container Registry:   seegregistry.azurecr.io
✅ App Service Plan:     seeg-app-plan (B1 Basic)
✅ Web App:              seeg-ai-api
✅ Document Intelligence: seeg-document-intelligence
```

### Commandes de Gestion

```bash
# Voir les logs
az webapp log tail --name seeg-ai-api --resource-group seeg-rg

# Redémarrer
az webapp restart --name seeg-ai-api --resource-group seeg-rg

# Voir le statut
az webapp show --name seeg-ai-api --resource-group seeg-rg --query state

# Mettre à jour l'image
az acr build --registry seegregistry --image seeg-api:latest --file Dockerfile .
az webapp restart --name seeg-ai-api --resource-group seeg-rg
```

### Migration des Données

#### Système de Migration Robuste

Le script `migrate_to_cosmos.py` gère automatiquement :
- ✅ Throttling (429) avec retry automatique
- ✅ Duplicata (E11000) ignorés automatiquement  
- ✅ Reprise possible en cas d'interruption
- ✅ Barre de progression en temps réel
- ✅ Statistiques détaillées

#### Depuis MongoDB Local vers Cosmos DB

```powershell
# 1. Export depuis MongoDB local
docker exec seeg-mongodb mongoexport `
  -u Sevan -p "SevanSeeg2025" `
  --authenticationDatabase admin `
  --db SEEG-AI `
  --collection candidats `
  --out /tmp/candidats_export.json

docker cp seeg-mongodb:/tmp/candidats_export.json ./candidats_export.json

# 2. Migration robuste vers Cosmos DB
# Récupérer la connection string
$connStr = az cosmosdb keys list --name seeg-ai --resource-group seeg-rg --type connection-strings --query "connectionStrings[0].connectionString" --output tsv

# Lancer la migration
python migrate_to_cosmos.py "$connStr"

# Ou utiliser .env
python migrate_to_cosmos.py
```

#### Migration Automatique lors du Déploiement

Le script `deploy_azure.ps1` propose automatiquement la migration et utilise le script robuste :

```powershell
.\deploy_azure.ps1
# Répondre 'o' quand on vous demande de migrer les données
```

#### Relancer une Migration Échouée

```powershell
# Le script peut être relancé autant de fois que nécessaire
# Il ignore automatiquement les documents déjà importés
python migrate_to_cosmos.py "$connectionString"
```

---

## 🧪 Tests

### Tests Unitaires

```powershell
# Tous les tests
pytest

# Tests spécifiques
pytest tests/test_models.py
pytest tests/test_mongodb.py
pytest tests/test_ocr.py
pytest tests/test_api.py

# Avec couverture
pytest --cov=src --cov-report=html
```

### Test Manuel d'un Candidat

```powershell
python test_one_candidate.py
```

### Test de l'API

```powershell
# Local
curl http://localhost:8000/health
curl http://localhost:8000/candidatures

# Production
curl https://seeg-ai-api.azurewebsites.net/health
curl https://seeg-ai-api.azurewebsites.net/candidatures
```

---

## 🛠️ Scripts Utilitaires

### MongoDB

```powershell
# Statistiques
.\scripts\mongodb_stats.ps1

# Backup
.\scripts\mongodb_backup.ps1

# CLI
.\scripts\mongodb_cli.sh  # Linux/Mac
docker exec -it seeg-mongodb mongosh -u Sevan -p SevanSeeg2025 --authenticationDatabase admin  # Windows

# Nettoyage
.\scripts\mongodb_clean.sh
```

### Vérification Configuration

```powershell
python scripts/check_setup.py
```

### Test API Complet

```powershell
.\TEST_API_ROUTES.ps1  # Windows
.\scripts\test_api.sh   # Linux/Mac
```

---

## 🐛 Dépannage

### MongoDB ne démarre pas

```powershell
# Vérifier Docker
docker ps

# Relancer MongoDB
docker-compose down -v
docker-compose up -d mongodb

# Vérifier les logs
docker logs seeg-mongodb
```

### Erreur de connexion MongoDB

```powershell
# Vérifier les credentials dans .env
# User: Sevan
# Password: SevanSeeg2025

# Tester la connexion
docker exec seeg-mongodb mongosh -u Sevan -p "SevanSeeg2025" --authenticationDatabase admin SEEG-AI --eval "db.candidats.countDocuments({})"
```

### Erreur OCR Azure

```bash
# Vérifier les credentials
az cognitiveservices account keys list --name seeg-document-intelligence --resource-group seeg-rg

# Tester l'endpoint
curl https://seeg-document-intelligence.cognitiveservices.azure.com/
```

### API ne démarre pas

```powershell
# Vérifier les dépendances
pip install -r requirements.txt

# Vérifier le port 8000
netstat -an | findstr "8000"

# Relancer
python run_api.py
```

### Erreur Cosmos DB (Throttling 429)

```
Error: TooManyRequests (429)
```

**Solution** : Le script `complete_migration.py` gère automatiquement le throttling avec des pauses entre les insertions.

### Problèmes Docker

```powershell
# Nettoyer Docker
docker system prune -a

# Relancer les services
docker-compose down -v
docker-compose up -d
```

---

## 📊 Schéma MongoDB

### Collection `candidats`

```javascript
{
  "_id": ObjectId,
  "application_id": UUID,                    // ID unique de la candidature
  "first_name": String,
  "last_name": String,
  "email": String,
  "date_candidature": ISODate,
  
  "offre": {
    "intitule": String,
    "reference": UUID,
    "type_contrat": String,
    "categorie": String,
    "lieu_travail": String,
    "missions_principales": String,
    "questions_mtp": {
      "metier": [String],
      "talent": [String],
      "paradigme": [String]
    }
  },
  
  "reponses_mtp": {
    "metier": [String],
    "talent": [String],
    "paradigme": [String]
  },
  
  "documents": {
    "cv": String,                            // Texte extrait par OCR
    "lettre_motivation": String,
    "diplome": String,
    "certificats": String
  },
  
  "statut": String,                          // en_attente, en_cours, accepte, refuse
  "date_creation": ISODate,
  "date_mise_a_jour": ISODate
}
```

---

## 📁 Structure du Projet

```
SEEG-AI/
│
├── src/
│   ├── __init__.py
│   ├── config.py                    # Configuration centralisée
│   ├── logger.py                    # Logging
│   ├── models.py                    # Modèles Pydantic
│   │
│   ├── database/
│   │   └── mongodb_client.py        # Client MongoDB
│   │
│   ├── services/
│   │   ├── supabase_client.py       # Téléchargement fichiers
│   │   └── azure_ocr.py             # Extraction OCR
│   │
│   ├── processor/
│   │   └── candidature_processor.py # Orchestration
│   │
│   └── api/
│       └── app.py                   # FastAPI endpoints
│
├── data/
│   └── Donnees_candidatures_SEEG.json  # 183 candidats
│
├── scripts/
│   ├── mongodb_backup.ps1
│   ├── mongodb_stats.ps1
│   └── check_setup.py
│
├── tests/
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
├── docker-compose.yml              # Orchestration
├── requirements.txt                # Dépendances Python
│
├── deploy_azure.ps1                # Script déploiement Azure
├── .env                            # Variables locales (gitignored)
├── env.production.seeg             # Template production
│
└── README.md                       # Cette documentation
```

---

## 💰 Coûts Estimés (Azure)

| Service | SKU | Coût Mensuel |
|---------|-----|--------------|
| App Service | B1 Basic | ~13€ |
| Cosmos DB | Serverless | ~7-10€ |
| Container Registry | Basic | ~5€ |
| Document Intelligence | Pay-as-you-go | ~1€ (initial) |
| **Total** | | **~25-30€/mois** |

---

## 🔐 Sécurité

### Bonnes Pratiques

- ✅ Credentials dans variables d'environnement
- ✅ `.env` dans `.gitignore`
- ✅ SSL/TLS pour Cosmos DB
- ✅ HTTPS pour l'API (Azure)
- ⚠️ **TODO** : Implémenter authentification API
- ⚠️ **TODO** : Migrer secrets vers Azure Key Vault

### Recommandations Production

1. **Azure Key Vault** : Stocker les secrets
2. **Managed Identity** : Authentification sans credentials
3. **Application Insights** : Monitoring et télémétrie
4. **HTTPS Only** : Forcer HTTPS sur App Service
5. **Rate Limiting** : Limiter les requêtes API

---

## 📞 Support

### Liens Utiles

- **API Production** : https://seeg-ai-api.azurewebsites.net
- **Documentation API** : https://seeg-ai-api.azurewebsites.net/docs
- **Portail Azure** : https://portal.azure.com
- **Azure CLI Docs** : https://docs.microsoft.com/cli/azure/

### Commandes Rapides

```bash
# Statut de l'API
curl https://seeg-ai-api.azurewebsites.net/health

# Logs Azure
az webapp log tail --name seeg-ai-api --resource-group seeg-rg

# Statistiques MongoDB
.\scripts\mongodb_stats.ps1

# Tests complets
pytest
```

---

## 📝 Changelog

### Version 1.0.0 (21 octobre 2025)

- ✅ Déploiement Azure réussi
- ✅ 183 candidatures migrées vers Cosmos DB
- ✅ API REST opérationnelle
- ✅ Documentation complète
- ✅ Tests automatiques
- ✅ Scripts de déploiement

---

## 📄 Licence

Propriété de la SEEG (Société d'Énergie et d'Eau du Gabon)

---

## ✅ Status Final

```
✅ Système SEEG-AI opérationnel
✅ API déployée sur Azure
✅ 183 candidatures traitées
✅ Tous les endpoints fonctionnels
✅ Documentation complète
✅ Prêt pour production
```

**Date de déploiement** : 21 octobre 2025  
**Version** : 1.0.0  
**Status** : 🟢 Production Ready

---

**Pour toute question, consulter la documentation Swagger : https://seeg-ai-api.azurewebsites.net/docs**
