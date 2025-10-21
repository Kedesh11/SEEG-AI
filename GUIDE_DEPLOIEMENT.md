# 🚀 Guide d'Utilisation du Script de Déploiement Amélioré

## 📋 Vue d'Ensemble

Le script `deploy_azure.ps1` a été amélioré pour gérer **tout le cycle de déploiement** :

```
✅ 1. Déploiement API sur Azure
✅ 2. Configuration Cosmos DB
✅ 3. Migration automatique des données
✅ 4. Tests de vérification
✅ 5. Rapport complet
```

---

## 🎯 Modes d'Utilisation

### Mode 1 : Déploiement Complet (Recommandé) ⭐

```powershell
.\deploy_azure.ps1
```

**Ce qui se passe** :
1. ✅ Vérification connexion Azure
2. ✅ Récupération credentials Cosmos DB
3. ✅ Création Container Registry (si nécessaire)
4. ✅ Build et push de l'image Docker (~5 min)
5. ✅ Création/mise à jour App Service
6. ✅ Configuration des variables d'environnement
7. ✅ **NOUVEAU** : Proposition de migration des données locales
8. ✅ **NOUVEAU** : Tests automatiques de l'API
9. ✅ Rapport complet avec statut

**Durée totale** : 15-20 minutes

---

### Mode 2 : Déploiement Rapide (Sans Build)

```powershell
.\deploy_azure.ps1 -SkipBuild
```

**Utile quand** :
- L'image Docker existe déjà dans le Container Registry
- Vous voulez juste mettre à jour la configuration
- Vous testez les paramètres

**Durée** : 2-3 minutes

---

### Mode 3 : Configuration Uniquement

```powershell
.\deploy_azure.ps1 -OnlyConfig
```

**Ce qui se fait** :
- ❌ Pas de build Docker
- ❌ Pas de redémarrage
- ✅ Mise à jour des variables d'environnement uniquement

**Utile pour** : Changer les credentials, URLs, etc.

**Durée** : 30 secondes

---

### Mode 4 : Sans Migration de Données

```powershell
.\deploy_azure.ps1 -SkipDataMigration
```

**Quand l'utiliser** :
- Vous n'avez pas de données locales
- Vous avez déjà migré les données
- Vous allez traiter les candidats directement en production

---

### Mode 5 : Sans Tests

```powershell
.\deploy_azure.ps1 -SkipTests
```

**Quand l'utiliser** :
- Déploiement très rapide
- Vous testerez manuellement plus tard
- Environnement de développement

---

### Combinaisons Possibles

```powershell
# Build + Config, mais pas de migration ni tests
.\deploy_azure.ps1 -SkipDataMigration -SkipTests

# Seulement la config et les tests (pas de rebuild)
.\deploy_azure.ps1 -SkipBuild -OnlyConfig

# Déploiement ultra-rapide (pour tester)
.\deploy_azure.ps1 -SkipBuild -SkipDataMigration -SkipTests
```

---

## 📊 Flux de Migration des Données

### Étape 7 : Migration Automatique

Quand vous lancez le script sans `-SkipDataMigration`, voici ce qui se passe :

```
┌─────────────────────────────────────┐
│ 1. Détection MongoDB local          │
│    docker ps --filter seeg-mongodb  │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ 2. Comptage des candidatures        │
│    db.candidats.countDocuments({})  │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ 3. Proposition de migration         │
│    "Migrer X candidatures? (o/N)"   │
└─────────────────────────────────────┘
         ↓ (si Oui)
┌─────────────────────────────────────┐
│ 4. Export vers fichier JSON         │
│    mongoexport → candidats_export   │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ 5. Copie vers hôte local            │
│    docker cp → ./candidats_export   │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ 6. Proposition d'import             │
│    "Importer maintenant? (o/N)"     │
└─────────────────────────────────────┘
         ↓ (si Oui)
┌─────────────────────────────────────┐
│ 7. Import vers Cosmos DB            │
│    mongoimport → Cosmos DB          │
└─────────────────────────────────────┘
```

### Exemple d'Interaction

```
7️⃣  Migration des données vers Cosmos DB...
  MongoDB local détecté
  📊 1 candidatures trouvées dans MongoDB local
  Voulez-vous migrer ces données vers Cosmos DB? (o/N): o
  Export des données...
  ✓ Export réussi: candidats_export.json
  Import vers Cosmos DB...
  ⚠️  Installez MongoDB Tools si pas déjà fait:
     https://www.mongodb.com/try/download/database-tools
  
  Commande pour importer:
  mongoimport --uri="mongodb+srv://Sevan:PASSWORD@seeg-ai..." --db SEEG-AI --collection candidats --file ./candidats_export.json
  
  Exécuter l'import maintenant? (o/N): o
  ✓ Import réussi vers Cosmos DB
```

---

## 🧪 Tests Automatiques

### Étape 8 : Vérification du Déploiement

Le script lance automatiquement 3 tests :

```
8️⃣  Vérification du déploiement...
  Attente du démarrage de l'application (30 secondes)...
  
  Test 1/3: Health check...
    ✓ Health check OK
  
  Test 2/3: Endpoint racine...
    ✓ Endpoint racine OK
  
  Test 3/3: Endpoint candidatures...
    ✓ Endpoint candidatures OK (1 candidatures)
  
  ✅ Tous les tests sont passés!
```

### Que Faire si un Test Échoue ?

```powershell
# Voir les logs en temps réel
az webapp log tail --name seeg-ai-api --resource-group seeg-rg

# Vérifier le statut
az webapp show --name seeg-ai-api --resource-group seeg-rg --query state

# Redémarrer si nécessaire
az webapp restart --name seeg-ai-api --resource-group seeg-rg

# Attendre 1-2 minutes et retester
curl https://seeg-ai-api.azurewebsites.net/health
```

---

## 📝 Rapport Final

À la fin du déploiement, vous obtenez un rapport complet :

```
================================
✅ DÉPLOIEMENT TERMINÉ !
================================

🌐 API accessible sur:
  https://seeg-ai-api.azurewebsites.net

📡 Endpoints disponibles:
  Health:       https://seeg-ai-api.azurewebsites.net/health
  Docs:         https://seeg-ai-api.azurewebsites.net/docs
  Candidatures: https://seeg-ai-api.azurewebsites.net/candidatures
  Recherche:    https://seeg-ai-api.azurewebsites.net/candidatures/search

🔍 Commandes utiles:
  Voir les logs:    az webapp log tail --name seeg-ai-api --resource-group seeg-rg
  Redémarrer:       az webapp restart --name seeg-ai-api --resource-group seeg-rg
  Voir le statut:   az webapp show --name seeg-ai-api --resource-group seeg-rg --query state

📊 Prochaines étapes:
  1. Vérifier l'API: curl https://seeg-ai-api.azurewebsites.net/health
  2. Traiter les candidats: python main.py (avec Cosmos DB configuré)
  3. Consulter les docs: https://seeg-ai-api.azurewebsites.net/docs

⏱️  L'application peut prendre 1-2 minutes pour démarrer complètement
```

---

## 🔄 Workflows Complets

### Workflow 1 : Premier Déploiement avec Données Locales

```powershell
# 1. Vérifier que Docker tourne et MongoDB a des données
docker ps
docker exec seeg-mongodb mongosh -u Sevan -p "SevanSeeg2025" --authenticationDatabase admin SEEG-AI --eval "db.candidats.countDocuments({})"

# 2. Se connecter à Azure
az login
az account set --subscription e44aff73-4ec5-4cf2-ad58-f8b24492970a

# 3. Déployer avec migration
.\deploy_azure.ps1

# Répondre "o" aux questions de migration

# 4. Vérifier
curl https://seeg-ai-api.azurewebsites.net/health
curl https://seeg-ai-api.azurewebsites.net/candidatures
```

---

### Workflow 2 : Déploiement Sans Données (Traitement Direct)

```powershell
# 1. Déployer sans migration
.\deploy_azure.ps1 -SkipDataMigration

# 2. Configurer .env pour Cosmos DB
# Modifier MONGODB_CONNECTION_STRING vers Cosmos DB

# 3. Traiter les candidats directement vers Cosmos DB
.\env\Scripts\Activate.ps1
python main.py

# 4. Vérifier dans l'API
curl https://seeg-ai-api.azurewebsites.net/candidatures
```

---

### Workflow 3 : Mise à Jour de la Configuration

```powershell
# Si vous changez une variable d'environnement (clé API, etc.)
.\deploy_azure.ps1 -OnlyConfig

# L'API redémarre automatiquement avec les nouvelles valeurs
```

---

### Workflow 4 : Rebuild après Modification du Code

```powershell
# Après avoir modifié le code Python
.\deploy_azure.ps1 -SkipDataMigration

# Ou plus rapide si vous avez déjà testé :
.\deploy_azure.ps1 -SkipDataMigration -SkipTests
```

---

## ⚠️ Prérequis pour MongoDB Tools

Pour que l'import automatique fonctionne, vous devez avoir **MongoDB Database Tools** installé :

### Windows

```powershell
# Télécharger depuis :
https://www.mongodb.com/try/download/database-tools

# Ou avec Chocolatey :
choco install mongodb-database-tools

# Vérifier l'installation
mongoimport --version
```

### Alternative : Import Manuel

Si l'import automatique échoue, utilisez la commande affichée par le script :

```bash
mongoimport --uri="mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256" --db SEEG-AI --collection candidats --file ./candidats_export.json
```

---

## 🎯 Résolution de Problèmes

### Problème 1 : Build Docker Échoue

```powershell
# Vérifier que Docker tourne
docker ps

# Relancer Docker Desktop si nécessaire
# Puis réessayer
.\deploy_azure.ps1
```

---

### Problème 2 : Tests Échouent (Timeout)

```powershell
# Normal au premier déploiement - l'app met du temps à démarrer
# Attendre 2-3 minutes puis tester manuellement
Start-Sleep -Seconds 120
curl https://seeg-ai-api.azurewebsites.net/health

# Si toujours pas OK, voir les logs
az webapp log tail --name seeg-ai-api --resource-group seeg-rg
```

---

### Problème 3 : Import Cosmos DB Échoue

```powershell
# Le fichier candidats_export.json a été créé
# Vous pouvez l'importer manuellement

# Récupérer la connection string
az cosmosdb keys list --name seeg-ai --resource-group seeg-rg --type connection-strings

# Importer
mongoimport --uri="VOTRE_CONNECTION_STRING" --db SEEG-AI --collection candidats --file ./candidats_export.json
```

---

### Problème 4 : MongoDB Local Non Détecté

```powershell
# Vérifier que le container tourne
docker ps | Select-String "seeg-mongodb"

# Si pas de résultat, lancer MongoDB
docker-compose up -d mongodb

# Puis relancer le script
.\deploy_azure.ps1
```

---

## 📊 Comparaison des Modes

| Mode | Build Docker | Migration | Tests | Durée | Usage |
|------|--------------|-----------|-------|-------|-------|
| **Complet** | ✅ | ✅ | ✅ | 15-20 min | Premier déploiement |
| **SkipBuild** | ❌ | ✅ | ✅ | 2-3 min | Config uniquement |
| **OnlyConfig** | ❌ | ❌ | ❌ | 30 sec | Variables seulement |
| **SkipDataMigration** | ✅ | ❌ | ✅ | 10-15 min | Sans données locales |
| **SkipTests** | ✅ | ✅ | ❌ | 10-15 min | Déploiement rapide |

---

## ✅ Checklist Avant Déploiement

```
□ Docker Desktop lancé
□ Azure CLI connecté (az login)
□ MongoDB local contient des données (optionnel)
□ Mot de passe Cosmos DB récupéré (fait automatiquement)
□ Fichier .env configuré localement (pour tests)
□ MongoDB Tools installé (pour import automatique)
```

---

## 🎊 Résumé

Le script `deploy_azure.ps1` amélioré gère maintenant **tout le cycle de vie** :

```
✅ Déploiement complet de l'API
✅ Configuration automatique de Cosmos DB
✅ Migration intelligente des données
✅ Tests automatiques de vérification
✅ Rapport détaillé avec statut
```

**Une seule commande suffit** : `.\deploy_azure.ps1` 🚀

