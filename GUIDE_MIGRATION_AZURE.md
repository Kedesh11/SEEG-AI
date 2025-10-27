# 🚀 Guide de Migration des Candidatures vers Azure Cosmos DB

## 📊 Contexte

Vous avez **40 candidats** dans `data/Donnees_candidatures_SEEG.json` qui doivent être poussés vers Azure Cosmos DB.

Il existe **DEUX MÉTHODES** pour effectuer cette migration.

---

## ✅ **MÉTHODE 1 : Migration Directe (RECOMMANDÉE)**

Cette méthode lit directement depuis `data/Donnees_candidatures_SEEG.json`, traite les documents avec OCR, et pousse vers Cosmos DB.

### Avantages
- ✅ **Une seule étape**
- ✅ Pas besoin de MongoDB local
- ✅ Traitement OCR complet
- ✅ Gestion automatique des duplicata

### Commandes

```powershell
# 1. Récupérer la connection string Cosmos DB
$cosmosConnStr = az cosmosdb keys list `
    --name seeg-ai `
    --resource-group seeg-rg `
    --type connection-strings `
    --query "connectionStrings[0].connectionString" `
    --output tsv

# 2. Vérifier que vous avez bien la connection string
echo $cosmosConnStr

# 3. Lancer la migration directe
python migrate_direct_to_cosmos.py "$cosmosConnStr"
```

### Durée estimée
- **40 candidats × ~40 secondes** = environ **25-30 minutes**
- Le script affiche la progression en temps réel

### ⚠️ Note
Le script utilise Azure Document Intelligence (OCR) qui a des coûts (~0.01€ par page).
Pour 40 candidats × 4 documents = **160 documents** ≈ **2-3€**

---

## 🔄 **MÉTHODE 2 : Migration en 3 Étapes (Classique)**

Cette méthode utilise MongoDB local comme intermédiaire.

### Étape 1 : Traiter localement avec MongoDB

```powershell
# 1. Démarrer MongoDB local
docker-compose up -d mongodb

# 2. Vérifier MongoDB
docker ps | findstr mongodb

# 3. Traiter les candidatures localement
python main.py
```

**Résultat**: Les 40 candidats sont maintenant dans MongoDB local avec OCR complet.

### Étape 2 : Exporter depuis MongoDB local

```powershell
# Export au format JSONL
docker exec seeg-mongodb mongoexport `
    -u Sevan -p "SevanSeeg2025" `
    --authenticationDatabase admin `
    --db SEEG-AI `
    --collection candidats `
    --out /tmp/candidats_export.json

# Copier le fichier exporté
docker cp seeg-mongodb:/tmp/candidats_export.json ./candidats_export.json

# Vérifier le fichier
Get-Content candidats_export.json | Measure-Object -Line
```

### Étape 3 : Migrer vers Cosmos DB

```powershell
# Récupérer la connection string
$cosmosConnStr = az cosmosdb keys list `
    --name seeg-ai `
    --resource-group seeg-rg `
    --type connection-strings `
    --query "connectionStrings[0].connectionString" `
    --output tsv

# Lancer la migration
python migrate_to_cosmos.py "$cosmosConnStr"
```

**Durée**: ~2-3 minutes (pas de traitement OCR, juste transfert de données)

---

## 📋 **Comparaison des Méthodes**

| Critère | Méthode 1 (Directe) | Méthode 2 (3 Étapes) |
|---------|---------------------|----------------------|
| **Complexité** | ⭐ Simple | ⭐⭐⭐ Complexe |
| **Étapes** | 1 commande | 3 étapes |
| **MongoDB local** | ❌ Pas nécessaire | ✅ Requis |
| **Durée** | ~30 min (avec OCR) | ~35 min total |
| **Gestion duplicata** | ✅ Automatique | ✅ Automatique |
| **Reprise possible** | ✅ Oui | ✅ Oui |
| **Recommandé pour** | Nouveaux candidats | Données déjà traitées |

---

## 🔍 **Vérification Post-Migration**

Après la migration, vérifiez que tout s'est bien passé:

### 1. Via Azure Portal
```
https://portal.azure.com
→ Cosmos DB → seeg-ai → Data Explorer
→ SEEG-AI → candidats
```

### 2. Via Azure CLI
```powershell
# Compter les documents (pas disponible directement en CLI)
# Utilisez le portal ou l'API
```

### 3. Via l'API REST
```powershell
# Health check
curl https://seeg-ai-api.azurewebsites.net/health

# Compter les candidatures
$candidats = Invoke-RestMethod -Uri "https://seeg-ai-api.azurewebsites.net/candidatures"
$candidats.Count

# Afficher les derniers ajoutés
$candidats | Select-Object -Last 5 | ForEach-Object {
    "$($_.first_name) $($_.last_name) - $($_.offre.intitule)"
}
```

### 4. Via Python
```python
from pymongo import MongoClient
from dotenv import load_dotenv
import os

load_dotenv()
connection_string = os.getenv("COSMOS_CONNECTION_STRING")

client = MongoClient(connection_string)
db = client["SEEG-AI"]
collection = db["candidats"]

# Compter
count = collection.count_documents({})
print(f"Total: {count} candidats")

# Lister les derniers
for doc in collection.find().sort("_id", -1).limit(5):
    print(f"- {doc['first_name']} {doc['last_name']}")
```

---

## ⚠️ **Gestion des Erreurs**

### Erreur: Throttling (429)
```
TooManyRequests (429): Request rate is large
```

**Solution**: Le script gère automatiquement avec retry et pause.
Attendez simplement que le script continue.

### Erreur: Duplicate Key (E11000)
```
E11000 duplicate key error
```

**Solution**: Normal ! Le candidat existe déjà, il est ignoré automatiquement.

### Erreur: Connection Timeout
```
ServerSelectionTimeoutError
```

**Solution**:
1. Vérifiez votre connexion internet
2. Vérifiez la connection string Cosmos DB
3. Vérifiez que Cosmos DB est bien démarré sur Azure

### Erreur: OCR Failed
```
Erreur extraction OCR
```

**Solution**:
1. Vérifiez les credentials Azure Document Intelligence
2. Vérifiez que le document est accessible sur Supabase
3. Le script continue avec les autres documents

---

## 📊 **Statistiques Attendues**

Pour **40 candidats** dans `data/Donnees_candidatures_SEEG.json`:

```
Total candidats:        40
Documents par candidat: ~4 (CV, lettre, diplôme, certificats)
Total documents OCR:    ~160

Durée traitement OCR:   ~5-7 sec/document
Durée téléchargement:   ~2 sec/document
Durée sauvegarde:       <1 sec/candidat

DURÉE TOTALE:          25-30 minutes
```

---

## 🎯 **Recommandation Finale**

**Pour votre cas (40 nouveaux candidats):**

✅ **Utilisez la MÉTHODE 1** (Migration Directe)

```powershell
# Une seule commande !
$cosmosConnStr = az cosmosdb keys list --name seeg-ai --resource-group seeg-rg --type connection-strings --query "connectionStrings[0].connectionString" --output tsv
python migrate_direct_to_cosmos.py "$cosmosConnStr"
```

**Avantages:**
- Simple et rapide
- Traitement OCR complet
- Pas besoin de MongoDB local
- Gestion automatique des duplicata

---

## 🔐 **Variable d'Environnement (Optionnel)**

Pour éviter de passer la connection string en paramètre, vous pouvez l'ajouter dans `.env`:

```env
# Ajouter dans .env
COSMOS_CONNECTION_STRING=mongodb://seeg-ai:***@seeg-ai.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb
```

Ensuite:
```powershell
python migrate_direct_to_cosmos.py
# La connection string sera lue automatiquement depuis .env
```

---

## 📞 **Support**

En cas de problème:

1. **Vérifier les logs**: Le script affiche tous les détails
2. **Relancer**: Le script peut être relancé sans problème (gère les duplicata)
3. **Vérifier Azure**: https://portal.azure.com → Cosmos DB → seeg-ai

---

## ✅ **Checklist de Migration**

- [ ] Connection string Cosmos DB récupérée
- [ ] Fichier `data/Donnees_candidatures_SEEG.json` présent (40 candidats)
- [ ] Azure Document Intelligence fonctionnel
- [ ] Supabase accessible
- [ ] Script `migrate_direct_to_cosmos.py` prêt
- [ ] Environnement virtuel activé (`.\env\Scripts\Activate.ps1`)
- [ ] Migration lancée
- [ ] Vérification post-migration effectuée
- [ ] API Azure testée

---

**Bonne migration ! 🚀**


