# 🔄 Flux de Déploiement Complet - SEEG-AI

## 📊 Vue d'Ensemble du Déploiement

```
┌─────────────────────────────────────────────────────────────────┐
│                 .\deploy_azure.ps1                              │
│              Script de Déploiement Amélioré                     │
└─────────────────────────────────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ÉTAPE 0: Vérifications Préliminaires │
        └───────────────────────────────────────┘
                            ↓
        ┌───────────────────┬───────────────────┐
        │ Azure CLI OK ?    │ Docker OK ?       │
        │ ✓ az login        │ ✓ docker ps       │
        └───────────────────┴───────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ÉTAPE 1: Récupération Credentials    │
        │  • Cosmos DB Connection String        │
        └───────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ÉTAPE 2: Container Registry          │
        │  • Création (si nécessaire)           │
        │  • seegregistry.azurecr.io            │
        └───────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ÉTAPE 3: Build Image Docker          │
        │  • FROM python:3.13-slim              │
        │  • COPY src/ requirements.txt         │
        │  • RUN pip install                    │
        │  • CMD uvicorn                        │
        │  • Push → ACR                         │
        │  ⏱️  ~5 minutes                        │
        └───────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ÉTAPE 4: App Service                 │
        │  • Création Plan (si nécessaire)      │
        │  • Création Web App (si nécessaire)   │
        │  • seeg-ai-api.azurewebsites.net      │
        └───────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ÉTAPE 5: Configuration Variables     │
        │  • AZURE_DOCUMENT_INTELLIGENCE_*      │
        │  • SUPABASE_*                         │
        │  • MONGODB_CONNECTION_STRING          │
        │  • MONGODB_DATABASE                   │
        └───────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ÉTAPE 6: Redémarrage Application     │
        │  az webapp restart                    │
        └───────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ✨ ÉTAPE 7: Migration Données        │
        │  (NOUVELLE FONCTIONNALITÉ)            │
        └───────────────────────────────────────┘
                            ↓
    ┌──────────────────┬──────────────────────┐
    │ MongoDB local ?  │ Données présentes ?  │
    └──────────────────┴──────────────────────┘
                ↓ OUI
    ┌───────────────────────────────────────────┐
    │  Proposition: Migrer vers Cosmos DB ?     │
    │  Réponse utilisateur: (o/N)               │
    └───────────────────────────────────────────┘
                ↓ OUI
    ┌───────────────────────────────────────────┐
    │  1. Export MongoDB → JSON                 │
    │     mongoexport                           │
    │  2. Copie vers hôte                       │
    │     docker cp                             │
    │  3. Import vers Cosmos DB                 │
    │     mongoimport                           │
    └───────────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ✨ ÉTAPE 8: Tests Automatiques       │
        │  (NOUVELLE FONCTIONNALITÉ)            │
        └───────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Attente 30 secondes (démarrage app)      │
    └───────────────────────────────────────────┘
                            ↓
    ┌─────────────┬─────────────┬───────────────┐
    │ Test 1/3    │ Test 2/3    │ Test 3/3      │
    │ /health     │ /           │ /candidatures │
    │ ✅ OK       │ ✅ OK       │ ✅ OK         │
    └─────────────┴─────────────┴───────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  ÉTAPE 9: Rapport Final               │
        │  • URLs de l'API                      │
        │  • Statut des tests                   │
        │  • Commandes utiles                   │
        │  • Prochaines étapes                  │
        └───────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │         ✅ DÉPLOIEMENT RÉUSSI !       │
        └───────────────────────────────────────┘
```

---

## 🎯 Détail de Chaque Étape

### ÉTAPE 0: Vérifications Préliminaires

```powershell
# Vérification Azure CLI
az account show

# Vérification Docker
docker ps
```

**Durée** : 5 secondes

---

### ÉTAPE 1: Récupération Credentials Cosmos DB

```powershell
az cosmosdb keys list \
  --name seeg-ai \
  --resource-group seeg-rg \
  --type connection-strings
```

**Résultat** :
```
mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/...
```

**Durée** : 10 secondes

---

### ÉTAPE 2: Container Registry

```powershell
# Création (si n'existe pas)
az acr create --name seegregistry --resource-group seeg-rg

# Connexion
az acr login --name seegregistry
```

**Résultat** : `seegregistry.azurecr.io`

**Durée** : 30 secondes (création) ou instantané (déjà existant)

---

### ÉTAPE 3: Build et Push Image Docker

```powershell
az acr build \
  --registry seegregistry \
  --image seeg-api:latest \
  --file Dockerfile \
  .
```

**Ce qui se passe** :
1. Upload du contexte (~50 MB)
2. Build de l'image
3. Installation des dépendances Python
4. Push vers ACR

**Durée** : 5-7 minutes

---

### ÉTAPE 4: App Service

```powershell
# Si n'existe pas :
az appservice plan create --name seeg-app-plan
az webapp create --name seeg-ai-api
az webapp config container set ...

# Si existe déjà :
# Mise à jour automatique de l'image
```

**Résultat** : `https://seeg-ai-api.azurewebsites.net`

**Durée** : 2-3 minutes (création) ou 30 secondes (mise à jour)

---

### ÉTAPE 5: Configuration Variables

```powershell
az webapp config appsettings set \
  --name seeg-ai-api \
  --settings \
    AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT="..." \
    AZURE_DOCUMENT_INTELLIGENCE_KEY="..." \
    SUPABASE_URL="..." \
    MONGODB_CONNECTION_STRING="..." \
    ...
```

**Variables configurées** : 10 variables d'environnement

**Durée** : 15 secondes

---

### ÉTAPE 6: Redémarrage

```powershell
az webapp restart --name seeg-ai-api
```

**Durée** : 10 secondes (commande) + 1-2 minutes (démarrage app)

---

### ✨ ÉTAPE 7: Migration Données (Nouveau)

#### Flux Détaillé

```
1. Détection MongoDB Local
   ↓
   docker ps --filter "name=seeg-mongodb"
   
2. Si trouvé → Comptage
   ↓
   docker exec ... db.candidats.countDocuments({})
   → Résultat: 1 candidature(s)
   
3. Proposition à l'utilisateur
   ↓
   "Voulez-vous migrer ces données vers Cosmos DB? (o/N)"
   
4. Si OUI → Export
   ↓
   docker exec ... mongoexport \
     --db SEEG-AI \
     --collection candidats \
     --out /tmp/candidats_export.json
   
5. Copie vers hôte
   ↓
   docker cp seeg-mongodb:/tmp/candidats_export.json ./
   
6. Proposition d'import
   ↓
   "Exécuter l'import maintenant? (o/N)"
   
7. Si OUI → Import Cosmos DB
   ↓
   mongoimport \
     --uri="mongodb+srv://..." \
     --db SEEG-AI \
     --collection candidats \
     --file ./candidats_export.json
```

**Durée** : 30 secondes - 2 minutes (selon nombre de documents)

**Note** : Peut être ignoré avec `-SkipDataMigration`

---

### ✨ ÉTAPE 8: Tests Automatiques (Nouveau)

#### Flux Détaillé

```
1. Attente démarrage app
   ↓
   Start-Sleep -Seconds 30
   
2. Test 1: Health Check
   ↓
   GET https://seeg-ai-api.azurewebsites.net/health
   → Attendu: {"status": "healthy", "database": "connected"}
   → ✅ ou ❌
   
3. Test 2: Root Endpoint
   ↓
   GET https://seeg-ai-api.azurewebsites.net/
   → Attendu: {"message": "API SEEG Candidatures", ...}
   → ✅ ou ❌
   
4. Test 3: Candidatures
   ↓
   GET https://seeg-ai-api.azurewebsites.net/candidatures
   → Attendu: Array de candidatures
   → ✅ ou ⚠️  (vide acceptable)
   
5. Rapport
   ↓
   "✅ Tous les tests sont passés!"
   ou
   "⚠️  Certains tests ont échoué"
```

**Durée** : 1 minute

**Note** : Peut être ignoré avec `-SkipTests`

---

### ÉTAPE 9: Rapport Final

```
================================
✅ DÉPLOIEMENT TERMINÉ !
================================

🌐 API accessible sur:
  https://seeg-ai-api.azurewebsites.net

📡 Endpoints disponibles:
  Health:       /health
  Docs:         /docs
  Candidatures: /candidatures
  Recherche:    /candidatures/search

🔍 Commandes utiles:
  Voir les logs:    az webapp log tail --name seeg-ai-api --resource-group seeg-rg
  Redémarrer:       az webapp restart --name seeg-ai-api --resource-group seeg-rg
  Voir le statut:   az webapp show --name seeg-ai-api --resource-group seeg-rg

📊 Prochaines étapes:
  1. Vérifier l'API
  2. Traiter les candidats
  3. Consulter les docs
```

---

## ⏱️ Durée Totale Estimée

| Scénario | Durée |
|----------|-------|
| **Premier déploiement complet** | 15-20 minutes |
| **Mise à jour (avec build)** | 10-12 minutes |
| **Mise à jour (sans build)** | 2-3 minutes |
| **Config uniquement** | 30 secondes |

---

## 🔀 Options de Déploiement

### Option 1 : Complet (Par Défaut)

```powershell
.\deploy_azure.ps1
```

**Inclut** : Tout (Build + Config + Migration + Tests)

---

### Option 2 : Sans Build

```powershell
.\deploy_azure.ps1 -SkipBuild
```

**Exclut** : ÉTAPE 3 (Build Docker)

**Durée gagnée** : -5 minutes

---

### Option 3 : Config Seulement

```powershell
.\deploy_azure.ps1 -OnlyConfig
```

**Exclut** : ÉTAPES 3, 6, 7, 8 (Build, Restart, Migration, Tests)

**Durée gagnée** : -15 minutes

---

### Option 4 : Sans Migration

```powershell
.\deploy_azure.ps1 -SkipDataMigration
```

**Exclut** : ÉTAPE 7 (Migration)

**Durée gagnée** : -1 minute

---

### Option 5 : Sans Tests

```powershell
.\deploy_azure.ps1 -SkipTests
```

**Exclut** : ÉTAPE 8 (Tests)

**Durée gagnée** : -1 minute

---

## 🎯 Choix du Mode selon le Contexte

| Contexte | Commande Recommandée |
|----------|----------------------|
| Premier déploiement | `.\deploy_azure.ps1` |
| Modification du code Python | `.\deploy_azure.ps1` |
| Changement de configuration | `.\deploy_azure.ps1 -SkipBuild` |
| Changement de variable d'env | `.\deploy_azure.ps1 -OnlyConfig` |
| Pas de données locales | `.\deploy_azure.ps1 -SkipDataMigration` |
| Déploiement rapide dev | `.\deploy_azure.ps1 -SkipBuild -SkipTests` |

---

## 📊 Résumé Visuel

```
AVANT (Script Original)
═══════════════════════
1. Build Docker          ✅
2. Deploy App Service    ✅
3. Configure variables   ✅
4. Restart               ✅
                         
→ Durée: 10-15 min
→ Données: Migration manuelle
→ Tests: Manuels


APRÈS (Script Amélioré)
═══════════════════════
1. Build Docker          ✅
2. Deploy App Service    ✅
3. Configure variables   ✅
4. Restart               ✅
5. Migration auto        ✨ NOUVEAU
6. Tests auto            ✨ NOUVEAU
7. Rapport détaillé      ✨ NOUVEAU

→ Durée: 15-20 min
→ Données: Migration automatique
→ Tests: Automatiques
→ Options: Flexibles (-Skip*)
```

---

## ✅ Checklist Complète

### Avant de Lancer

```
□ Docker Desktop lancé
□ Azure CLI connecté (az login)
□ Subscription correcte (e44aff73-4ec5-4cf2-ad58-f8b24492970a)
□ MongoDB local actif (si migration souhaitée)
□ MongoDB Tools installé (si import auto souhaité)
```

### Pendant l'Exécution

```
□ Observation des logs
□ Réponse aux questions de migration (o/N)
□ Attente du build Docker (patience !)
```

### Après le Déploiement

```
□ Vérifier health check
□ Tester les endpoints
□ Consulter la documentation Swagger
□ Traiter les candidats (si pas encore fait)
```

---

## 🎊 Résultat Final

Après exécution réussie :

```
✅ API déployée sur Azure
✅ Cosmos DB connectée
✅ Données migrées (si applicable)
✅ Tests passés
✅ Documentation accessible
✅ Prêt pour production !
```

**URL de l'API** : `https://seeg-ai-api.azurewebsites.net`

**Endpoints** :
- 🟢 GET `/health` → Health check
- 🟢 GET `/` → Info API
- 🟢 GET `/docs` → Documentation Swagger
- 🟢 GET `/candidatures` → Liste complète
- 🟢 GET `/candidatures/search` → Recherche

---

**Tout est prêt pour le lancement !** 🚀

