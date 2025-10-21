# ✅ Système SEEG-AI - Prêt pour Azure

## 🎯 État Actuel

### ✅ Tests Locaux Réussis

```
✓ Téléchargement depuis Supabase (application-documents)
✓ OCR Azure Document Intelligence fonctionnel
✓ Sauvegarde MongoDB avec ID unique
✓ API FastAPI opérationnelle
✓ Docker containers fonctionnels
```

### 📊 Exemple de Résultat

```
Candidat traité: Eric Hervé EYOGO TOUNG
Email: meejetjunior@gmail.com
Poste: Directeur Juridique, Communication & RSE
Documents extraits:
  ✓ CV: 9438 caractères
  ✓ Lettre: 2834 caractères
  ✓ Diplôme: 10717 caractères
  ✓ Certificats: 6832 caractères

💾 Sauvegardé avec ID: 68f77d46cd6ed5c7ea2e64f8
```

---

## 🚀 Déploiement sur Azure - 3 Options

### Option 1 : Script Automatique (Recommandé) ✨

```powershell
# Déploiement complet (Build + Config)
.\deploy_azure.ps1

# Seulement mise à jour de la config (plus rapide)
.\deploy_azure.ps1 -OnlyConfig

# Sans rebuild de l'image (utilise l'existante)
.\deploy_azure.ps1 -SkipBuild
```

**Durée estimée** : 10-15 minutes

---

### Option 2 : Manuel avec CLI Azure

Suivez le guide complet : [`DEPLOIEMENT_AZURE_COMPLET.md`](./DEPLOIEMENT_AZURE_COMPLET.md)

**Durée estimée** : 20-30 minutes

---

### Option 3 : Portail Azure

1. Créer un Container Registry
2. Build l'image : `docker build -t seeg-ai:latest .`
3. Push vers ACR
4. Créer une Web App depuis le portail
5. Configurer les variables d'environnement

**Durée estimée** : 30-45 minutes

---

## 📋 Prérequis pour le Déploiement

### ✅ Ressources Azure Déjà Créées

```
✓ Cosmos DB MongoDB API
  - Nom: seeg-ai
  - Admin: Sevan
  - Location: francecentral

✓ Document Intelligence
  - Nom: seeg-document-intelligence
  - Endpoint: https://seeg-document-intelligence.cognitiveservices.azure.com/
  - Key: c692c5eb3c8c4f269af44c16ec339a7a

✓ Supabase
  - URL: https://fyiitzndlqcnyluwkpqp.supabase.co
  - Bucket: application-documents
```

### 🔧 Outils Requis

```
✓ Azure CLI installé
✓ Docker Desktop en cours d'exécution
✓ Connexion Azure active (az login)
```

---

## 🎬 Étapes Rapides pour Déployer

### 1. Récupérer le Mot de Passe Cosmos DB

```bash
az cosmosdb keys list \
  --name seeg-ai \
  --resource-group seeg-rg \
  --type connection-strings \
  --output json
```

**Copiez** le `connectionString` (remplacez PASSWORD dans les scripts).

---

### 2. Exécuter le Script de Déploiement

```powershell
# Déploiement complet
.\deploy_azure.ps1
```

Le script va :
1. ✅ Vérifier la connexion Azure
2. ✅ Récupérer les credentials Cosmos DB
3. ✅ Créer le Container Registry (si nécessaire)
4. ✅ Builder et pusher l'image Docker
5. ✅ Créer l'App Service (si nécessaire)
6. ✅ Configurer toutes les variables d'environnement
7. ✅ Redémarrer l'application

---

### 3. Attendre le Démarrage (1-2 minutes)

```bash
# Voir les logs en temps réel
az webapp log tail --name seeg-ai-api --resource-group seeg-rg
```

---

### 4. Tester l'API Déployée

```powershell
$API_URL = "https://seeg-ai-api.azurewebsites.net"

# Health check
Invoke-RestMethod -Uri "$API_URL/health"

# Voir les candidatures
$candidats = Invoke-RestMethod -Uri "$API_URL/candidatures"
$candidats.Count

# Documentation interactive
Start-Process "$API_URL/docs"
```

---

## 📊 Migration des Données vers Cosmos DB

### Export depuis MongoDB Local

```powershell
# Export
docker exec seeg-mongodb mongoexport `
  -u Sevan -p "SevanSeeg2025" `
  --authenticationDatabase admin `
  --db SEEG-AI `
  --collection candidats `
  --out /tmp/candidats_export.json

# Copier vers l'hôte
docker cp seeg-mongodb:/tmp/candidats_export.json ./candidats_export.json
```

### Import vers Cosmos DB

```bash
# Remplacez PASSWORD par le mot de passe Cosmos DB
mongoimport \
  --uri="mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256" \
  --db SEEG-AI \
  --collection candidats \
  --file ./candidats_export.json
```

---

## 🔄 Workflow Complet : Développement → Production

### Développement Local

```powershell
# 1. Activer l'environnement virtuel
.\env\Scripts\Activate.ps1

# 2. Traiter les candidats
python main.py

# 3. Lancer l'API en local
python run_api.py

# 4. Tester localement
Invoke-RestMethod -Uri "http://localhost:8000/health"
```

### Déploiement Azure

```powershell
# 1. Déployer
.\deploy_azure.ps1

# 2. Migrer les données
# (voir section Migration ci-dessus)

# 3. Tester en production
Invoke-RestMethod -Uri "https://seeg-ai-api.azurewebsites.net/health"
```

---

## 🔒 Sécurité (Recommandations Production)

### 1. Utiliser Azure Key Vault

```bash
# Créer le Key Vault
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
  --value "mongodb+srv://Sevan:PASSWORD@..."
```

### 2. Activer l'Identité Managée

```bash
# Sur l'App Service
az webapp identity assign \
  --name seeg-ai-api \
  --resource-group seeg-rg

# Donner accès au Key Vault
PRINCIPAL_ID=$(az webapp identity show \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --query principalId \
  --output tsv)

az keyvault set-policy \
  --name seeg-keyvault \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

### 3. Utiliser les Références Key Vault

```bash
az webapp config appsettings set \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --settings \
    AZURE_DOCUMENT_INTELLIGENCE_KEY="@Microsoft.KeyVault(SecretUri=https://seeg-keyvault.vault.azure.net/secrets/DocumentIntelligenceKey/)"
```

---

## 📊 Monitoring (Recommandé)

### Application Insights

```bash
# Créer
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

# Configurer l'App Service
az webapp config appsettings set \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="$INSIGHTS_KEY"
```

---

## ✅ Checklist Finale Avant Déploiement

```
✅ Docker Desktop lancé
✅ Azure CLI connecté (az login)
✅ Mot de passe Cosmos DB récupéré
✅ Fichier .env configuré localement (pour les tests)
✅ Tests locaux réussis (python test_one_candidate.py)
✅ API locale fonctionne (http://localhost:8000/health)
✅ MongoDB local contient des données
```

---

## 🎯 Commandes Post-Déploiement

### Voir les Logs

```bash
# Temps réel
az webapp log tail --name seeg-ai-api --resource-group seeg-rg

# Télécharger
az webapp log download --name seeg-ai-api --resource-group seeg-rg
```

### Redémarrer

```bash
az webapp restart --name seeg-ai-api --resource-group seeg-rg
```

### Vérifier le Statut

```bash
az webapp show \
  --name seeg-ai-api \
  --resource-group seeg-rg \
  --query "{Name:name, State:state, URL:defaultHostName}" \
  --output table
```

### Mettre à Jour l'Image

```bash
# Rebuild
az acr build \
  --registry seegregistry \
  --image seeg-api:latest \
  --file Dockerfile \
  .

# Redémarrer pour charger la nouvelle image
az webapp restart --name seeg-ai-api --resource-group seeg-rg
```

---

## 🌐 URLs Finales

### API de Production

```
Base URL: https://seeg-ai-api.azurewebsites.net

Endpoints:
  GET  /                                  → Info API
  GET  /health                            → Health check
  GET  /docs                              → Documentation interactive
  GET  /candidatures                      → Toutes les candidatures
  GET  /candidatures/search               → Recherche
       ?first_name=...
       ?last_name=...
       ?email=...
```

### Bases de Données

```
MongoDB Local (Dev):
  URL: http://localhost:8081 (Mongo Express)
  Connection: mongodb://Sevan:SevanSeeg2025@localhost:27017

Cosmos DB (Production):
  Connection: mongodb+srv://Sevan:PASSWORD@seeg-ai.mongocluster.cosmos.azure.com/...
```

---

## 📞 Support et Ressources

### Documentation Complète

- [`DEPLOIEMENT_AZURE_COMPLET.md`](./DEPLOIEMENT_AZURE_COMPLET.md) - Guide détaillé
- [`README.md`](./README.md) - Documentation principale
- [`GET_AZURE_CREDENTIALS.md`](./GET_AZURE_CREDENTIALS.md) - Récupérer les credentials

### Scripts Utiles

```
deploy_azure.ps1              → Déploiement automatique
scripts/mongodb_backup.ps1    → Backup MongoDB
scripts/mongodb_stats.ps1     → Statistiques
test_one_candidate.py         → Tester un candidat
```

---

## 🎊 Prêt pour le Lancement !

Tout est en place pour le déploiement sur Azure :

1. ✅ Code testé et fonctionnel
2. ✅ Docker configuré
3. ✅ Azure resources provisionnées
4. ✅ Scripts de déploiement prêts
5. ✅ Documentation complète

**Exécutez simplement** :

```powershell
.\deploy_azure.ps1
```

Et votre API sera en ligne en 10-15 minutes ! 🚀

